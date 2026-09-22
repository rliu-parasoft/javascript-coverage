#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)"
# shellcheck source=bitbucket-common.sh
source "${SCRIPT_DIR}/bitbucket-common.sh"

bb_skill_require_tools || exit $?

pr_url="${1:-}"
if [[ -z "$pr_url" ]]; then
  pr_url="$("${SCRIPT_DIR}/discover-pr-url.sh")" || exit $?
fi

if [[ "$pr_url" =~ ^(https?://[^/]+)/projects/([^/]+)/repos/([^/]+)/pull-requests/([0-9]+)(/.*)?$ ]]; then
  base_url="${BASH_REMATCH[1]}"
  project="${BASH_REMATCH[2]}"
  repo="${BASH_REMATCH[3]}"
  pr_id="${BASH_REMATCH[4]}"
else
  printf 'unsupported PR URL format: %s\n' "$pr_url" >&2
  exit 12
fi

limit="${BITBUCKET_ACTIVITY_LIMIT:-200}"
activities_url="${base_url}/rest/api/latest/projects/${project}/repos/${repo}/pull-requests/${pr_id}/activities?limit=${limit}"
bb_skill_api_get "$activities_url"
