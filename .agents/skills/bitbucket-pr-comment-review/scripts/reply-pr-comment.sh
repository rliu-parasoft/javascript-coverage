#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd -P)"
# shellcheck source=bitbucket-common.sh
source "${SCRIPT_DIR}/bitbucket-common.sh"

usage() {
  cat <<'USAGE'
Usage:
  reply-pr-comment.sh --comment-id <id> [--text <reply> | --text-file <file>] [--pr-url <url>] [--resolve]

Description:
  Optionally adds a reply to a Bitbucket PR comment thread and optionally
  resolves the parent comment.
  When --resolve is used, verifies the parent thread is effectively resolved.

Options:
  --comment-id <id>   Parent comment id to reply to (required)
  --text <reply>      Reply text (optional; use with or without --resolve)
  --text-file <file>  Path to file containing reply text (optional)
  --pr-url <url>      Bitbucket PR URL; if omitted, auto-discovered from branch
  --resolve           Resolve the parent comment (works with or without reply)
  -h, --help          Show this help text
USAGE
}

bb_skill_api_request() {
  local method url data_file auth_header
  method="$1"
  url="$2"
  data_file="${3:-}"
  auth_header="$(bb_skill_auth_header)" || return $?
  if [[ -n "$data_file" ]]; then
    curl --silent --show-error --fail \
      -H "$auth_header" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -X "$method" \
      --data "@$data_file" \
      "$url"
    return $?
  fi
  curl --silent --show-error --fail \
    -H "$auth_header" \
    -H "Accept: application/json" \
    -X "$method" \
    "$url"
}

bb_skill_require_tools || exit $?

pr_url=""
comment_id=""
reply_text=""
reply_text_file=""
has_text_flag=0
has_text_file_flag=0
resolve_parent=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr-url)
      [[ $# -ge 2 ]] || { printf 'missing value for %s\n' "$1" >&2; exit 64; }
      pr_url="$2"
      shift 2
      ;;
    --comment-id)
      [[ $# -ge 2 ]] || { printf 'missing value for %s\n' "$1" >&2; exit 64; }
      comment_id="$2"
      shift 2
      ;;
    --text)
      [[ $# -ge 2 ]] || { printf 'missing value for %s\n' "$1" >&2; exit 64; }
      reply_text="$2"
      has_text_flag=1
      shift 2
      ;;
    --text-file)
      [[ $# -ge 2 ]] || { printf 'missing value for %s\n' "$1" >&2; exit 64; }
      reply_text_file="$2"
      has_text_file_flag=1
      shift 2
      ;;
    --resolve)
      resolve_parent=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ -z "$comment_id" ]]; then
  printf 'missing required option: --comment-id\n' >&2
  usage >&2
  exit 64
fi

if [[ ! "$comment_id" =~ ^[0-9]+$ ]]; then
  printf 'invalid --comment-id (must be numeric): %s\n' "$comment_id" >&2
  exit 64
fi

if [[ "$has_text_flag" -eq 1 && "$has_text_file_flag" -eq 1 ]]; then
  printf 'use only one of --text or --text-file\n' >&2
  exit 64
fi

if [[ "$has_text_file_flag" -eq 1 ]]; then
  if [[ ! -f "$reply_text_file" ]]; then
    printf 'text file not found: %s\n' "$reply_text_file" >&2
    exit 66
  fi
  reply_text="$(cat "$reply_text_file")"
fi

if [[ "$has_text_flag" -eq 1 && -z "$reply_text" ]]; then
  printf 'reply text is empty\n' >&2
  exit 64
fi

if [[ "$has_text_file_flag" -eq 1 && -z "$reply_text" ]]; then
  printf 'reply text is empty\n' >&2
  exit 64
fi

if [[ -z "$reply_text" && "$resolve_parent" -ne 1 ]]; then
  printf 'missing action: provide --text/--text-file and/or --resolve\n' >&2
  exit 64
fi

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

reply_payload_file=""
resolve_payload_file=""
cleanup() {
  [[ -n "$reply_payload_file" ]] && rm -f "$reply_payload_file"
  [[ -n "$resolve_payload_file" ]] && rm -f "$resolve_payload_file"
}
trap cleanup EXIT

comments_url="${base_url}/rest/api/latest/projects/${project}/repos/${repo}/pull-requests/${pr_id}/comments"
comment_url="${comments_url}/${comment_id}"

reply_comment_id=""
if [[ -n "$reply_text" ]]; then
  reply_payload_file="$(mktemp)"
  jq -n \
    --arg text "$reply_text" \
    --argjson parent_id "$comment_id" \
    '{text:$text,parent:{id:$parent_id}}' > "$reply_payload_file"
  reply_result="$(bb_skill_api_request POST "$comments_url" "$reply_payload_file")" || exit $?
  reply_comment_id="$(jq -r '.id // empty' <<<"$reply_result")"
fi

resolved_state=""
resolved_thread_resolved=""
resolved_effective_state=""
if [[ "$resolve_parent" -eq 1 ]]; then
  resolve_payload_file="$(mktemp)"
  parent_comment_json="$(bb_skill_api_request GET "$comment_url")" || exit $?
  parent_version="$(jq -r '.version // empty' <<<"$parent_comment_json")"
  parent_text="$(jq -r '.text // ""' <<<"$parent_comment_json")"
  if [[ -z "$parent_version" || ! "$parent_version" =~ ^[0-9]+$ ]]; then
    printf 'failed to read parent comment version for id=%s\n' "$comment_id" >&2
    exit 65
  fi
  jq -n \
    --arg text "$parent_text" \
    --argjson version "$parent_version" \
    '{text:$text,version:$version,state:"RESOLVED",threadResolved:true}' > "$resolve_payload_file"
  bb_skill_api_request PUT "$comment_url" "$resolve_payload_file" >/dev/null || exit $?
  verified_parent_comment_json="$(bb_skill_api_request GET "$comment_url")" || exit $?
  resolved_state="$(jq -r '.state // empty' <<<"$verified_parent_comment_json")"
  resolved_thread_resolved="$(jq -r '
    if .threadResolved == true then "true"
    elif .threadResolved == false then "false"
    else ""
    end
  ' <<<"$verified_parent_comment_json")"
  resolved_effective_state="$(jq -r '
    if .state != null then .state
    elif ((.threadResolved // false) == true) then "RESOLVED"
    else "OPEN"
    end
  ' <<<"$verified_parent_comment_json")"
  if [[ "$resolved_thread_resolved" != "true" || "$resolved_effective_state" != "RESOLVED" ]]; then
    printf 'thread resolve verification failed for comment id=%s: state=%s threadResolved=%s effective_state=%s\n' \
      "$comment_id" "${resolved_state:-<missing>}" "${resolved_thread_resolved:-<missing>}" "$resolved_effective_state" >&2
    exit 67
  fi
fi

jq -n \
  --arg pr_url "$pr_url" \
  --argjson parent_comment_id "$comment_id" \
  --arg reply_comment_id "$reply_comment_id" \
  --arg resolved_state "$resolved_state" \
  --arg resolved_thread_resolved "$resolved_thread_resolved" \
  --arg resolved_effective_state "$resolved_effective_state" \
  '{
    pr_url: $pr_url,
    parent_comment_id: $parent_comment_id,
    reply_comment_id: (if $reply_comment_id == "" then null else ($reply_comment_id | tonumber) end),
    parent_resolved_state: (if $resolved_state == "" then null else $resolved_state end),
    parent_thread_resolved: (
      if $resolved_thread_resolved == "" then null
      elif $resolved_thread_resolved == "true" then true
      else false
      end
    ),
    parent_effective_state: (if $resolved_effective_state == "" then null else $resolved_effective_state end)
  }'