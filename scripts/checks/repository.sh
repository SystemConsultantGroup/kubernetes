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
(
  cd argocd/charts/application/files
  sha256sum --check envoy_html_injector.wasm.sha256
)

assert_value() {
  local state_expression="$1" manifest="$2" manifest_expression="$3" expected actual
  expected="$(yq -r "$state_expression" state.yaml)"
  actual="$(yq -r "$manifest_expression" "$manifest")"
  [[ $actual == "$expected" ]] || {
    echo "$manifest has $actual but state.yaml requires $expected" >&2
    return 1
  }
}

assert_value '.argocd.version' argocd/platform/argocd/application.yaml '.spec.sources[0].targetRevision'
assert_value '.cilium.version' argocd/platform/cilium/application.yaml '.spec.sources[0].targetRevision'
assert_value '."envoy-gateway".version' argocd/platform/envoy-gateway/application.yaml '.spec.sources[0].targetRevision | sub("^v"; "")'
assert_value '."gateway-api".version' argocd/platform/gateway-api/application.yaml '.spec.source.targetRevision | sub("^v"; "")'
assert_value '.external-secrets.version' argocd/platform/external-secrets/application.yaml '.spec.sources[0].targetRevision'
assert_value '.local-path-provisioner.revision' argocd/platform/local-path-provisioner/application.yaml '.spec.sources[0].targetRevision'
assert_value '.local-path-provisioner.helper' argocd/platform/local-path-provisioner/values.yaml '.helperImage.tag'
assert_value '.percona-operator.version' argocd/platform/percona-operator/application.yaml '.spec.sources[0].targetRevision'
assert_value '.pxc.versions.alumni' argocd/platform/mysql/manifests/clusters/alumni.yaml '.spec.pxc.image | split("@")[0] | sub("^.*:"; "") | split("-")[0]'
assert_value '.pxc.versions.central' argocd/platform/mysql/manifests/clusters/central.yaml '.spec.pxc.image | split("@")[0] | sub("^.*:"; "") | split("-")[0]'
assert_value '.reloader.chart' argocd/platform/reloader/application.yaml '.spec.sources[0].targetRevision'
assert_value '.vault.chart' argocd/platform/vault/application.yaml '.spec.sources[0].targetRevision'
assert_value '.cert-manager.version' argocd/platform/cert-manager/application.yaml '.spec.sources[0].targetRevision | sub("^v"; "")'
assert_value '.external-dns.version' argocd/platform/external-dns-scg.sh/application.yaml '.spec.sources[0].targetRevision'

for directory in argocd argocd/platform/gateway argocd/platform/mysql/manifests argocd/platform/vault/manifests argocd/platform/cert-manager/manifests; do
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
  helm template "$release" argocd/charts/application --namespace "$release" "$@" >"$output"
  # A non-empty namespace placeholder prevents Bash's whitespace IFS from
  # shifting the name into the namespace column and skipping length checks.
  resources="$(yq eval -r '[.kind // "", .metadata.namespace // "-", .metadata.name // ""] | @tsv' "$output")"
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
  done < <(yq eval-all -rN 'select(.kind == "HTTPRoute") | .spec.hostnames[]?' "$output")
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

injector_values="$TEMPORARY_DIRECTORY/html-injector.yaml"
cat >"$injector_values" <<'EOF'
_context:
  application: injector-test
  instance:
    type: production
web:
  http:
    port: 8080
    domain: injector.example.org
    inject: '<script src="/notice.js" defer></script>'
  source:
    repository: https://github.com/example/example.git
    revision: 0123456789abcdef0123456789abcdef01234567
  image: example.org/example/example@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
EOF
injector_output="$TEMPORARY_DIRECTORY/html-injector-rendered.yaml"
validate_render "$injector_output" injector-test --values "$injector_values"
[[ $(yq eval-all -r 'select(.kind == "HTTPRoute") | .spec.rules[].backendRefs[].name' "$injector_output") == injector-test-web ]]
[[ $(yq eval-all -r 'select(.kind == "Service" and .metadata.name == "injector-test-web") | .spec.ports[0].targetPort' "$injector_output") == http ]]
[[ $(yq eval-all -r 'select(.kind == "EnvoyExtensionPolicy") | .spec.targetRefs[0].sectionName' "$injector_output") == injector-test-web-1 ]]
[[ $(yq eval-all -r 'select(.kind == "EnvoyExtensionPolicy") | .spec.wasm[0].config' "$injector_output") == '<script src="/notice.js" defer></script>' ]]

# Production CIDR access: exercise the same Helm/schema path used by Argo CD.
access_base="$TEMPORARY_DIRECTORY/access-base.yaml"
access_values="$TEMPORARY_DIRECTORY/access-values.yaml"
access_output="$TEMPORARY_DIRECTORY/access-rendered.yaml"
cat >"$access_base" <<'EOF'
_context:
  application: access
  instance:
    type: production
web:
  http:
    port: 8080
    domain:
      - shop.example.org
      - name: external.example.org
        external: true
    rules:
      - name: api
        matches:
          - path:
              type: PathPrefix
              value: /api
        backendRefs:
          - name: api
      - name: web
api:
  http:
    port: 9000
    allowCIDRs:
      - 115.145.150.0/24
    inject: '<script src="/notice.js" defer></script>'
admin:
  http:
    port: 8080
    domain: admin.example.org
    allowCIDRs:
      - 203.0.113.10/32
EOF
# Reuse the synthetic immutable lock without coupling the fixture to a live app.
LOCK="$injector_values" yq -i '
  .web.source = load(strenv(LOCK)).web.source |
  .web.image = load(strenv(LOCK)).web.image |
  .api.source = .web.source | .api.image = .web.image |
  .admin.source = .web.source | .admin.image = .web.image
' "$access_base"

render_access() {
  validate_render "$access_output" access-production --values "$access_values" "$@"
}

assert_access_count() {
  local expected="$1" actual
  actual="$(yq eval-all '[select(.kind == "SecurityPolicy")] | length' "$access_output")"
  [[ $actual == "$expected" ]] || {
    echo "Expected $expected access policies, got $actual" >&2
    return 1
  }
}

reject_access() {
  local expected="$1"
  shift
  if helm template access-production argocd/charts/application --namespace access-production --values "$access_values" "$@" >"$access_output" 2>"$TEMPORARY_DIRECTORY/access-error"; then
    echo "Expected access validation to fail: $expected $*" >&2
    return 1
  fi
  grep -qF "$expected" "$TEMPORARY_DIRECTORY/access-error" || {
    cat "$TEMPORARY_DIRECTORY/access-error" >&2
    return 1
  }
}

cp "$access_base" "$access_values"
render_access
assert_access_count 3
# Two domains targeting api share its list; the independent admin has its own.
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .spec.targetRefs[0].sectionName' "$access_output" | sort) == $'access-admin-1\napi\napi' ]]
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy" and .spec.targetRefs[0].sectionName == "api") | .spec.authorization.rules[0].principal.clientCIDRs | join(",")' "$access_output" | sort -u) == '115.145.150.0/24' ]]
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy" and .spec.targetRefs[0].sectionName == "access-admin-1") | .spec.authorization.rules[0].principal.clientCIDRs[]' "$access_output") == '203.0.113.10/32' ]]
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .spec.authorization.defaultAction' "$access_output" | sort -u) == Deny ]]
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .spec.authorization.rules[].action' "$access_output" | sort -u) == Allow ]]
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .metadata.annotations."argocd.argoproj.io/sync-wave"' "$access_output" | sort -u) == -1 ]]
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .spec.targetRefs[0].kind' "$access_output" | sort -u) == HTTPRoute ]]
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .spec.targetRefs[0].group' "$access_output" | sort -u) == gateway.networking.k8s.io ]]
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .apiVersion' "$access_output" | sort -u) == gateway.envoyproxy.io/v1alpha1 ]]
route_rules="$(yq eval-all -rN 'select(.kind == "HTTPRoute") | .metadata.name as $route | .spec.rules[] | [$route, .name] | @tsv' "$access_output")"
while IFS= read -r target; do
  grep -qxF "$target" <<<"$route_rules"
done < <(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .spec.targetRefs[] | [.name, .sectionName] | @tsv' "$access_output")
[[ $(yq eval-all '[select(.kind == "EnvoyExtensionPolicy")] | length' "$access_output") == 2 ]]
# Routing still goes directly to the same Services: no sidecar or proxy backend.
[[ $(yq eval-all -rN 'select(.kind == "HTTPRoute") | .spec.rules[] | select(.name == "api") | .backendRefs[0].name' "$access_output" | sort -u) == access-api ]]

# Omission/removal is open; an explicit /0 is valid and is not a platform allow-list.
yq 'del(.api.http.allowCIDRs, .admin.http.allowCIDRs)' "$access_base" >"$access_values"
render_access
assert_access_count 0
render_access --set-json 'api.http.allowCIDRs=["0.0.0.0/0"]'
assert_access_count 2
[[ $(yq eval-all -rN 'select(.kind == "SecurityPolicy") | .spec.authorization.rules[0].principal.clientCIDRs | join(",")' "$access_output" | sort -u) == '0.0.0.0/0' ]]

# The production field must never override restricted testing/preview listeners.
cp "$access_base" "$access_values"
render_access --set _context.instance.type=testing
assert_access_count 0
render_access --set _context.instance.type=preview --set _context.instance.workload=api --set _context.instance.pullRequest=1
assert_access_count 0
for policy in testing-access preview-access; do
  [[ $(POLICY="$policy" yq eval-all -r 'select(.kind == "SecurityPolicy" and .metadata.name == strenv(POLICY)) | .spec.authorization.defaultAction' argocd/platform/gateway/security-policy.yaml) == Deny ]]
  [[ $(POLICY="$policy" yq eval-all -r 'select(.kind == "SecurityPolicy" and .metadata.name == strenv(POLICY)) | .spec.authorization.rules[0].principal.clientCIDRs | join(",")' argocd/platform/gateway/security-policy.yaml) == '115.145.150.0/24,10.244.0.0/23' ]]
done

# Generated Service names and explicit same-namespace references cannot bypass access.
for reference in '{"name":"api"}' '{"name":"access-api"}' '{"name":"access-api","namespace":"access-production","group":"","kind":"Service","port":80}'; do
  cp "$access_base" "$access_values"
  render_access --set-json "web.http.rules[0].backendRefs=[$reference]"
  assert_access_count 3
done

# Authorization cannot differ within one rule, even for a zero-weight backend.
for reference in '{"name":"web"}' '{"name":"web","weight":0}' '{"name":"unknown"}' '{"name":"access-api","namespace":"another-production"}' '{"name":"api","group":"example.org","kind":"Backend"}' '{"name":"admin"}'; do
  cp "$access_base" "$access_values"
  reject_access 'different allowCIDRs' --set-json "web.http.rules[0].backendRefs=[{\"name\":\"api\"},$reference]"
done
# Identical lists work in either order; the owning web workload's list is not inherited.
yq '.admin.http.allowCIDRs = (.api.http.allowCIDRs | reverse) | .web.http.rules[0].backendRefs += [{"name": "admin"}]' "$access_base" >"$access_values"
render_access
assert_access_count 3

# Mirrors use native Service names (no new alias rewriting), at both filter levels.
mirror='{"type":"RequestMirror","requestMirror":{"backendRef":{"name":"access-api","port":80},"percent":100}}'
for filters in 'web.http.rules[0].filters' 'web.http.rules[0].backendRefs[0].filters'; do
  cp "$access_base" "$access_values"
  render_access --set-json "$filters=[$mirror]"
  assert_access_count 3
  # An unrestricted response backend cannot forward a copy to a restricted workload.
  reject_access 'different allowCIDRs' --set-json "$filters=[$mirror]" --set web.http.rules[0].backendRefs[0].name=web
  reject_access 'different allowCIDRs' --set-json "$filters=[$mirror]" --set "${filters}[0].requestMirror.backendRef.namespace=another-production"
done

# Backend-free redirect rules use their owner, without adding a Service backend.
cp "$access_base" "$access_values"
render_access --set-json 'admin.http.rules=[{"filters":[{"type":"RequestRedirect","requestRedirect":{"scheme":"https"}}]}]'
assert_access_count 3
[[ $(yq eval-all -r 'select(.kind == "HTTPRoute") | .spec.rules[] | select(.name == "access-admin-1") | has("backendRefs")' "$access_output") == false ]]
# Ambiguous sections must not attach a restricted policy to an open sibling rule.
reject_access 'duplicate rule name' --set web.http.rules[1].name=api

# Policies use the same collision-resistant naming helper as other chart resources.
yq '._context.application = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" | .web.http.rules[0].name = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"' "$access_base" >"$access_values"
render_access
assert_access_count 3

# Schema validation covers hidden preview workloads too, rather than trusting the CRD.
cp "$access_base" "$access_values"
for invalid in '[]' 'null' '"115.145.150.0/24"' '[123]' '[null]' '["115.145.150.0/24","115.145.150.0/24"]'; do
  reject_access 'allowCIDRs' --set-json "api.http.allowCIDRs=$invalid"
done
for cidr in '0.0.0.0' '1.2.3.4/33' '256.0.0.0/24' '01.2.3.4/24' '1.2.3/24' '1.2.3.4/-1' '1.2.3.4/01' '1.2.3.4/999' '1.2.3.4/24junk' ' 1.2.3.4/24' '1.2.3.4/24 ' '::/0' '2001:db8::/32' '::ffff:192.0.2.1/128'; do
  reject_access 'allowCIDRs' --set-string "api.http.allowCIDRs[0]=$cidr"
done
reject_access 'allowCIDRs' --set-json 'api.http.allowCIDRs=[]' --set _context.instance.type=preview --set _context.instance.workload=web --set _context.instance.pullRequest=1
# IPv4 prefix boundaries and host bits are valid.
render_access --set-json 'api.http.allowCIDRs=["0.0.0.0/0","255.255.255.255/32","192.0.2.10/24"]'
assert_access_count 3

# Exercise real values-file merge semantics: null cannot silently remove a list.
yq '.api.http.allowCIDRs = null' "$access_base" >"$access_values"
reject_access 'allowCIDRs'
yq '.api.http.allowCIDRs = ["115.145.150.0/24"]' "$access_base" >"$access_values"
printf 'api:\n  http:\n    allowCIDRs: null\n' >"$TEMPORARY_DIRECTORY/access-null-override.yaml"
reject_access 'allowCIDRs' --values "$TEMPORARY_DIRECTORY/access-null-override.yaml"
