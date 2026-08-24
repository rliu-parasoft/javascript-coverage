#!/usr/bin/env bash

bb_skill_require_tools() {
  for tool in git curl jq base64; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      printf 'missing required tool: %s\n' "$tool" >&2
      return 2
    fi
  done
}

bb_skill_username() {
  if [[ -n "${BITBUCKET_USER:-}" ]]; then
    printf '%s\n' "$BITBUCKET_USER"
    return 0
  fi
  if [[ -n "${BITUBCKET_USER:-}" ]]; then
    printf '%s\n' "$BITUBCKET_USER"
    return 0
  fi
  id -un
}

bb_skill_token() {
  if [[ -n "${BITBUCKET_TOKEN:-}" ]]; then
    printf '%s\n' "$BITBUCKET_TOKEN"
    return 0
  fi
  if [[ -n "${BITBUCKET_PAT:-}" ]]; then
    printf '%s\n' "$BITBUCKET_PAT"
    return 0
  fi
  printf 'missing credentials: set BITBUCKET_TOKEN (preferred) or BITBUCKET_PAT\n' >&2
  return 3
}

bb_skill_auth_header() {
  local user token encoded
  user="$(bb_skill_username)" || return $?
  token="$(bb_skill_token)" || return $?
  encoded="$(printf '%s:%s' "$user" "$token" | base64 | tr -d '\n')"
  printf 'Authorization: Basic %s\n' "$encoded"
}

bb_skill_repo_triplet() {
  local origin host path base_url project repo
  origin="$(git remote get-url origin 2>/dev/null)" || {
    printf 'failed to read origin remote from git\n' >&2
    return 4
  }

  case "$origin" in
    https://*|http://*)
      host="$(printf '%s' "$origin" | sed -E 's#^[a-z]+://([^/]+)/.*#\1#')"
      path="$(printf '%s' "$origin" | sed -E 's#^[a-z]+://[^/]+/(.*)$#\1#')"
      ;;
    ssh://*)
      host="$(printf '%s' "$origin" | sed -E 's#^ssh://[^@]+@([^/:]+)(:[0-9]+)?/.*#\1#')"
      path="$(printf '%s' "$origin" | sed -E 's#^ssh://[^@]+@[^/:]+(:[0-9]+)?/(.*)$#\2#')"
      ;;
    *@*:* )
      host="$(printf '%s' "$origin" | sed -E 's#^[^@]+@([^:]+):.*#\1#')"
      path="$(printf '%s' "$origin" | sed -E 's#^[^@]+@[^:]+:(.*)$#\1#')"
      ;;
    *)
      printf 'unsupported origin URL format: %s\n' "$origin" >&2
      return 5
      ;;
  esac

  path="${path%.git}"
  path="${path#scm/}"
  base_url="https://${host}"

  if [[ "$path" =~ ^projects/([^/]+)/repos/([^/]+)$ ]]; then
    project="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  else
    project="${path%%/*}"
    repo="${path#*/}"
    repo="${repo%%/*}"
  fi

  if [[ -z "$project" || -z "$repo" || "$project" == "$path" ]]; then
    printf 'failed to derive {project,repo} from origin URL: %s\n' "$origin" >&2
    return 6
  fi

  printf '%s|%s|%s\n' "$base_url" "$project" "$repo"
}

bb_skill_api_get() {
  local url auth_header
  url="$1"
  auth_header="$(bb_skill_auth_header)" || return $?
  curl --silent --show-error --fail \
    -H "$auth_header" \
    -H "Accept: application/json" \
    "$url"
}
