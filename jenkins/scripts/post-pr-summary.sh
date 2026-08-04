#!/bin/bash
#
# post-pr-summary.sh
#
# Post ${ARTIFACTS_DIR}/summary.md as a comment on the current Bitbucket PR.
# Intended for the Jenkins pipeline post stage: attempt to publish the comment
# regardless of whether earlier stages succeeded or failed.
#
# Required environment variables:
#   BITBUCKET_API   - Bitbucket REST API prefix
#   API_USERNAME    - Bitbucket API user name
#   API_PASSWORD    - Bitbucket API password / token
#   CHANGE_ID       - PR number; empty or "null" for non-PR builds (skipped silently)
#   ARTIFACTS_DIR   - Artifacts directory (default: artifacts)
#
# Design notes:
#   - Non-PR build: exit 0 immediately
#   - summary.md missing: exit 0 (avoid polluting the post-stage outcome)
#   - API call fails: exit non-zero so Jenkins reports the failure
#
set -euo pipefail

ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"
SUMMARY_FILE="${ARTIFACTS_DIR}/summary.md"

if [[ -z "${CHANGE_ID:-}" || "${CHANGE_ID:-}" == "null" ]]; then
    echo "Not a pull-request build; skip posting summary."
    exit 0
fi

if [[ ! -s "${SUMMARY_FILE}" ]]; then
    echo "No ${SUMMARY_FILE} to post; skip."
    exit 0
fi

# ---------------------------------------------------------------------------

echo "---- posting summary to PR ----"
: "${BITBUCKET_API:?BITBUCKET_API is required}"
: "${API_USERNAME:?API_USERNAME is required}"
: "${API_PASSWORD:?API_PASSWORD is required}"

SUMMARY=$(jq -Rsa . < "${SUMMARY_FILE}")

curl --fail --silent --show-error \
    -u "${API_USERNAME}:${API_PASSWORD}" \
    -H "Content-Type: application/json" \
    --url "${BITBUCKET_API}/pull-requests/${CHANGE_ID}/comments" \
    --data "{\"text\":${SUMMARY}}" \
    -o "${ARTIFACTS_DIR}/comment.json"

echo "Posted summary to PR #${CHANGE_ID}."
echo "-----------------------"
echo

