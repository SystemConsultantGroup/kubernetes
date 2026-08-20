#!/usr/bin/env bash
set -euo pipefail

ROOT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPORARY_DIRECTORY="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMPORARY_DIRECTORY"
}
trap cleanup EXIT
cd "$ROOT_DIRECTORY"

mapfile -t shell_sources < <(find scripts/k.commands scripts/checks -name '*.sh' -type f -print)
bash -n scripts/k scripts/k.completions "${shell_sources[@]}"
shellcheck --shell=bash --exclude=SC1090,SC2016,SC2034,SC2148 scripts/k scripts/k.completions "${shell_sources[@]}"
mapfile -t markdown_files < <(find . -name '*.md' -type f -not -path './workers/kms/node_modules/*' -print)
lychee --offline --no-progress --exclude 'working/ignored/' "${markdown_files[@]}"

assert_value() {
  local state_expression="$1" manifest="$2" manifest_expression="$3" expected actual
  expected="$(yq -r "$state_expression" state.yaml)"
  actual="$(yq -r "$manifest_expression" "$manifest")"
  [[ $actual == "$expected" ]] || {
    echo "$manifest has $actual but state.yaml requires $expected" >&2
    return 1
  }
}

assert_value '.external-secrets.version' argocd/platform/external-secrets/application.yaml '.spec.sources[0].targetRevision'
assert_value '.local-path-provisioner.revision' argocd/platform/local-path-provisioner/application.yaml '.spec.sources[0].targetRevision'
assert_value '.local-path-provisioner.helper' argocd/platform/local-path-provisioner/values.yaml '.helperImage.tag'
assert_value '.reloader.chart' argocd/platform/reloader/application.yaml '.spec.sources[0].targetRevision'
assert_value '.vault.chart' argocd/platform/vault/application.yaml '.spec.sources[0].targetRevision'
assert_value '.cert-manager.version' argocd/platform/cert-manager/application.yaml '.spec.sources[0].targetRevision | sub("^v"; "")'
assert_value '.external-dns.version' argocd/platform/external-dns-scg.sh/application.yaml '.spec.sources[0].targetRevision'

for directory in argocd argocd/platform/gateway argocd/platform/vault/manifests argocd/platform/cert-manager/manifests; do
  output="$TEMPORARY_DIRECTORY/$(tr '/' '-' <<<"$directory").yaml"
  kubectl kustomize "$directory" >"$output"
done

validate_custom_render() {
  local output="$1" application="$2" resource_kind resource_namespace resource_name
  while IFS=$'\t' read -r resource_kind resource_namespace resource_name; do
    if [[ $resource_kind == Namespace && $resource_name != "$application" ]]; then
      echo "Custom application $application declares namespace $resource_name" >&2
      return 1
    fi
    if [[ -n $resource_namespace && $resource_namespace != "$application" ]]; then
      echo "Custom application $application targets namespace $resource_namespace" >&2
      return 1
    fi
  done < <(yq eval -r '[.kind // "", .metadata.namespace // "", .metadata.name // ""] | @tsv' "$output")
}

validate_render() {
  local output="$1" release="$2" resources duplicate resource_kind resource_namespace resource_name hostname hostname_label
  shift 2
  helm template "$release" argocd/charts/application "$@" >"$output"
  resources="$(yq eval -r '[.kind // "", .metadata.namespace // "", .metadata.name // ""] | @tsv' "$output")"
  duplicate="$(sort <<<"$resources" | uniq -d)"
  [[ -z $duplicate ]] || {
    echo "Duplicate rendered resources in $release:" >&2
    printf '%s\n' "$duplicate" >&2
    return 1
  }
  while IFS=$'\t' read -r resource_kind resource_namespace resource_name; do
    [[ ${#resource_name} -le 63 ]] || {
      echo "Oversized rendered resource name in $release: $resource_kind/$resource_name" >&2
      return 1
    }
  done <<<"$resources"
  while IFS= read -r hostname; do
    hostname_label="${hostname%%.*}"
    [[ -z $hostname || ${#hostname_label} -le 63 ]] || {
      echo "Oversized rendered hostname label in $release: $hostname" >&2
      return 1
    }
  done < <(yq eval-all -r 'select(.kind == "HTTPRoute") | .spec.hostnames[]?' "$output")
}

for application_directory in applications/*; do
  [[ -d $application_directory ]] || continue
  application="${application_directory##*/}"
  [[ $application =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ && ${#application} -le 63 ]] || {
    echo "Invalid application name: $application" >&2
    exit 1
  }
  metadata="$application_directory/meta.yaml"
  customization="$application_directory/kustomization.yaml"
  if [[ -f $metadata && -f $customization ]]; then
    echo "$application mixes managed and custom modes" >&2
    exit 1
  fi
  if [[ -f $customization ]]; then
    [[ ! -d $application_directory/instances ]] || {
      echo "$application mixes custom mode with managed instances" >&2
      exit 1
    }
    custom_output="$TEMPORARY_DIRECTORY/$application-custom.yaml"
    kubectl kustomize "$application_directory" >"$custom_output"
    validate_custom_render "$custom_output" "$application"
    continue
  fi
  [[ -f $metadata && -f $application_directory/instances/production.yaml ]] || {
    echo "$application is missing its managed metadata or production lock" >&2
    exit 1
  }
  metadata_workloads="$(yq -r 'keys | .[]' "$metadata" | sort)"
  while IFS= read -r workload; do
    [[ $workload =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ && ${#workload} -le 63 ]] || {
      echo "Invalid workload name in $metadata: $workload" >&2
      exit 1
    }
    if [[ $(yq -r ".\"$workload\" | has(\"source\") or has(\"image\")" "$metadata") == true ]]; then
      echo "Runtime locks belong in instances, not $metadata" >&2
      exit 1
    fi
  done <<<"$metadata_workloads"
  for instance in production testing; do
    lock="$application_directory/instances/$instance.yaml"
    [[ -f $lock ]] || continue
    lock_workloads="$(yq -r 'keys | .[]' "$lock" | sort)"
    [[ $lock_workloads == "$metadata_workloads" ]] || {
      echo "$lock does not contain exactly the workloads from $metadata" >&2
      exit 1
    }
    while IFS= read -r workload; do
      lock_fields="$(yq -r ".\"$workload\" | keys | .[]" "$lock" | sort)"
      [[ $lock_fields == $'image\nsource' ]] || {
        echo "$lock may contain only source and image for $workload" >&2
        exit 1
      }
    done <<<"$metadata_workloads"
    identity="$application-$instance"
    ((${#identity} <= 63)) || {
      echo "Generated Application name exceeds 63 characters: $identity" >&2
      exit 1
    }
    validate_render "$TEMPORARY_DIRECTORY/$identity.yaml" "$identity" --values "$metadata" --values "$lock" --set "_context.application=$application" --set "_context.instance.type=$instance"
  done
  while IFS= read -r lock; do
    workload="$(basename "$(dirname "$lock")")"
    pull_request="$(basename "$lock" .yaml)"
    grep -qxF "$workload" <<<"$metadata_workloads" || {
      echo "$lock references unknown workload $workload" >&2
      exit 1
    }
    [[ $pull_request =~ ^[1-9][0-9]*$ ]] || {
      echo "Invalid pull request filename: $lock" >&2
      exit 1
    }
    lock_fields="$(yq -r 'keys | .[]' "$lock" | sort)"
    [[ $lock_fields == $'image\nsource' ]] || {
      echo "$lock may contain only source and image" >&2
      exit 1
    }
    identity="$application-preview-$workload-$pull_request"
    ((${#identity} <= 63)) || {
      echo "Generated preview identity exceeds 63 characters: $identity" >&2
      exit 1
    }
    preview_values="$TEMPORARY_DIRECTORY/preview-values.yaml"
    yq -n "._context.application = \"$application\" | ._context.instance.type = \"preview\" | ._context.instance.workload = \"$workload\" | ._context.instance.pullRequest = $pull_request | .\"$workload\" = load(\"$lock\")" >"$preview_values"
    validate_render "$TEMPORARY_DIRECTORY/$identity.yaml" "$identity" --values "$metadata" --values "$preview_values"
  done < <(find "$application_directory/instances/preview" -mindepth 2 -maxdepth 2 -name '*.yaml' -type f 2>/dev/null | sort)
done

synthetic_values="$TEMPORARY_DIRECTORY/long-names.yaml"
cat >"$synthetic_values" <<'EOF'
_context:
  application: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  instance:
    type: production
sharedprefix-one:
  source:
    repository: https://github.com/example/example.git
    revision: 0123456789abcdef0123456789abcdef01234567
  image: example.org/example/example@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
sharedprefix-two:
  source:
    repository: https://github.com/example/example.git
    revision: 0123456789abcdef0123456789abcdef01234567
  image: example.org/example/example@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
EOF
validate_render "$TEMPORARY_DIRECTORY/long-names-rendered.yaml" long-names --values "$synthetic_values"
