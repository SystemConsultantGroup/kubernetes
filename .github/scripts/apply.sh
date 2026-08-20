#!/usr/bin/env bash
set -euo pipefail

request="${REQUEST:?}"

jq --exit-status '
  type == "object" and
  keys == ["application", "image", "instance", "operation", "pullRequest", "sourceBranch", "sourceRepository", "sourceRevision", "version", "workflowRevision", "workload"] and
  .version == 1 and
  (.operation == "set" or .operation == "remove") and
  (.application | test("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$")) and
  (.workload | test("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$")) and
  (.instance == "production" or .instance == "testing" or .instance == "preview") and
  (.sourceRepository | test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")) and
  (.sourceBranch | test("^[A-Za-z0-9._/-]+$")) and
  (.sourceRevision | test("^[0-9a-f]{40}$")) and
  (.workflowRevision | test("^[0-9a-f]{40}$")) and
  (if .instance == "preview" then (.pullRequest | type == "number" and . > 0 and floor == .) else .pullRequest == null end) and
  (if .operation == "remove" then .instance == "preview" and .image == null else (.image | type == "string" and test("^(ghcr\\.io|docker\\.io)/[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)+@sha256:[0-9a-f]{64}$")) end) and
  (if .instance == "production" then .sourceBranch == "main" elif .instance == "testing" then .sourceBranch == "testing" else true end)
' <<<"$request" >/dev/null

application="$(jq -r '.application' <<<"$request")"
image="$(jq -r '.image // ""' <<<"$request")"
instance="$(jq -r '.instance' <<<"$request")"
operation="$(jq -r '.operation' <<<"$request")"
pull_request="$(jq -r '.pullRequest // ""' <<<"$request")"
source_branch="$(jq -r '.sourceBranch' <<<"$request")"
source_repository="$(jq -r '.sourceRepository' <<<"$request")"
source_revision="$(jq -r '.sourceRevision' <<<"$request")"
workflow_revision="$(jq -r '.workflowRevision' <<<"$request")"
workload="$(jq -r '.workload' <<<"$request")"
application_directory="applications/$application"
metadata="$application_directory/meta.yaml"
production_lock="$application_directory/instances/production.yaml"
source_repository_url="https://github.com/$source_repository.git"

[[ -f $metadata && -f $production_lock ]] || {
  echo "Unknown managed application: $application" >&2
  exit 1
}
WORKLOAD="$workload" yq --exit-status 'has(strenv(WORKLOAD))' "$metadata" >/dev/null
WORKLOAD="$workload" yq --exit-status 'has(strenv(WORKLOAD))' "$production_lock" >/dev/null
expected_source_repository="$(WORKLOAD="$workload" yq -r '.[strenv(WORKLOAD)].source.repository' "$production_lock")"
expected_source_repository="${expected_source_repository#https://github.com/}"
expected_source_repository="${expected_source_repository%.git}"
[[ ${expected_source_repository,,} == "${source_repository,,}" ]] || {
  echo "Source repository does not own $application/$workload" >&2
  exit 1
}

if [[ $operation == set ]]; then
  expected_image="$(WORKLOAD="$workload" yq -r '.[strenv(WORKLOAD)].image' "$production_lock")"
  expected_image="${expected_image%@sha256:*}"
  requested_image="${image%@sha256:*}"
  [[ $requested_image == "$expected_image" ]] || {
    echo "Image repository does not match $application/$workload" >&2
    exit 1
  }
fi

stale=false
if [[ $instance == preview ]]; then
  pull_request_state="$(gh api "repos/$source_repository/pulls/$pull_request")"
  actual_source_repository="$(jq -r '.head.repo.full_name' <<<"$pull_request_state")"
  actual_state="$(jq -r '.state' <<<"$pull_request_state")"
  [[ ${actual_source_repository,,} == "${source_repository,,}" ]] || {
    echo "Pull request $pull_request is not a same-repository pull request" >&2
    exit 1
  }
  if [[ $operation == remove ]]; then
    [[ $actual_state == closed ]] || stale=true
    actual_revision="$(jq -r '.head.sha' <<<"$pull_request_state")"
  else
    [[ $actual_state == open ]] || stale=true
    actual_revision="$(jq -r '.merge_commit_sha' <<<"$pull_request_state")"
  fi
else
  actual_revision="$(gh api "repos/$source_repository/commits/$source_branch" --jq '.sha')"
fi

if [[ $actual_revision != "$source_revision" ]]; then
  stale=true
fi
if [[ $stale == true ]]; then
  printf "The request for \`%s/%s\` is stale and was ignored.\n" "$application" "$workload" >>"$GITHUB_STEP_SUMMARY"
  exit 0
fi

if [[ $operation == set ]]; then
  gh attestation verify "oci://$image" \
    --repo "$source_repository" \
    --source-digest "$source_revision" \
    --signer-workflow SystemConsultantGroup/kubernetes/.github/workflows/build-image.yaml \
    --signer-digest "$workflow_revision"
fi

if [[ $instance == preview ]]; then
  lock="$application_directory/instances/preview/$workload/$pull_request.yaml"
else
  lock="$application_directory/instances/$instance.yaml"
  [[ -f $lock ]] || {
    echo "Missing $instance instance lock for $application" >&2
    exit 1
  }
  WORKLOAD="$workload" yq --exit-status 'has(strenv(WORKLOAD))' "$lock" >/dev/null
fi

if [[ $operation == remove ]]; then
  rm -f "$lock"
elif [[ $instance == preview ]]; then
  mkdir -p "$(dirname "$lock")"
  SOURCE_REPOSITORY_URL="$source_repository_url" SOURCE_REVISION="$source_revision" IMAGE="$image" yq --null-input '
    .source.repository = strenv(SOURCE_REPOSITORY_URL) |
    .source.revision = strenv(SOURCE_REVISION) |
    .image = strenv(IMAGE)
  ' >"$lock"
else
  WORKLOAD="$workload" SOURCE_REPOSITORY_URL="$source_repository_url" SOURCE_REVISION="$source_revision" IMAGE="$image" yq --inplace '
    .[strenv(WORKLOAD)].source.repository = strenv(SOURCE_REPOSITORY_URL) |
    .[strenv(WORKLOAD)].source.revision = strenv(SOURCE_REVISION) |
    .[strenv(WORKLOAD)].image = strenv(IMAGE)
  ' "$lock"
fi

if [[ -f $lock ]]; then
  git add --intent-to-add -- "$lock"
fi
mapfile -t changed_files < <(git diff --name-only)
if ((${#changed_files[@]} == 0)); then
  printf "The instance lock for \`%s/%s\` already has the requested state.\n" "$application" "$workload" >>"$GITHUB_STEP_SUMMARY"
  exit 0
fi
[[ ${#changed_files[@]} == 1 && ${changed_files[0]} == "$lock" ]] || {
  echo "Apply changed files outside $lock" >&2
  printf '%s\n' "${changed_files[@]}" >&2
  exit 1
}

git config user.name github-actions\[bot\]
git config user.email 41898282+github-actions\[bot\]@users.noreply.github.com
if [[ $instance == preview ]]; then
  destination="$application/$workload/preview-$pull_request"
else
  destination="$application/$workload/$instance"
fi
if [[ $operation == remove ]]; then
  message="Remove $destination"
else
  message="Apply ${source_revision:0:12} to $destination"
fi
git add -- "$lock"
git commit -m "$message"
git pull --rebase origin main
git push origin HEAD:main
printf "Applied \`%s/%s\` to \`%s\` in commit \`%s\`.\n" "$application" "$workload" "$instance" "$(git rev-parse HEAD)" >>"$GITHUB_STEP_SUMMARY"
