#!/usr/bin/env bash
set -o pipefail

if ! command -v jq >/dev/null 2>&1; then
  printf 'missing required tool: jq\n' >&2
  exit 2
fi

input="${1:-}"
if [[ -n "$input" ]]; then
  jq '
    [
      .values[]
      | select(.comment != null)
      | select((.comment.state // "OPEN") != "RESOLVED")
      | {
          comment_id: .comment.id,
          parent_comment_id: (.comment.parent.id // null),
          state: (.comment.state // "OPEN"),
          author: (.comment.author.displayName // .comment.author.name // "unknown"),
          severity: (.comment.severity // null),
          path: (.comment.anchor.path // null),
          line: (.comment.anchor.line // null),
          text: (.comment.text // "")
        }
    ]
  ' "$input"
  exit $?
fi

jq '
  [
    .values[]
    | select(.comment != null)
    | select((.comment.state // "OPEN") != "RESOLVED")
    | {
        comment_id: .comment.id,
        parent_comment_id: (.comment.parent.id // null),
        state: (.comment.state // "OPEN"),
        author: (.comment.author.displayName // .comment.author.name // "unknown"),
        severity: (.comment.severity // null),
        path: (.comment.anchor.path // null),
        line: (.comment.anchor.line // null),
        text: (.comment.text // "")
      }
  ]
'
