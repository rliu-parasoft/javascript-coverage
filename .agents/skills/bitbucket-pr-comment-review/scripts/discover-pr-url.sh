#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)"
# shellcheck source=bitbucket-common.sh
source "${SCRIPT_DIR}/bitbucket-common.sh"

bb_skill_require_tools || exit $?

branch="${1:-}"
if [[ -z "$branch" ]]; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
fi

repo_triplet="$(bb_skill_repo_triplet)" || exit $?
IFS='|' read -r base_url project repo <<<"$repo_triplet"

pr_list_url="${base_url}/rest/api/latest/projects/${project}/repos/${repo}/pull-requests?state=OPEN&limit=200"
pr_list_json="$(bb_skill_api_get "$pr_list_url")" || exit $?

matches="$(
  jq --arg branch "$branch" '
    [
      .values[]
      | select(
          (.fromRef.displayId == $branch)
          or ((.fromRef.id // "") | endswith("/" + $branch))
        )
      | { id, title, fromRef: .fromRef.displayId, toRef: .toRef.displayId }
    ]
  ' <<<"$pr_list_json"
)"

match_count="$(jq 'length' <<<"$matches")"
if [[ "$match_count" -eq 1 ]]; then
  pr_id="$(jq -r '.[0].id' <<<"$matches")"
  printf '%s/projects/%s/repos/%s/pull-requests/%s/overview\n' \
    "$base_url" "$project" "$repo" "$pr_id"
  exit 0
fi

if [[ "$match_count" -eq 0 ]]; then
  printf 'no open pull request found for branch: %s\n' "$branch" >&2
  exit 10
fi

printf 'multiple open pull requests found for branch: %s\n' "$branch" >&2
jq -r --arg base "$base_url" --arg project "$project" --arg repo "$repo" '
  .[]
  | "- PR #\(.id): \(.title)\n  URL: \($base)/projects/\($project)/repos/\($repo)/pull-requests/\(.id)/overview\n  from: \(.fromRef) -> \(.toRef)"
' <<<"$matches" >&2
exit 11
