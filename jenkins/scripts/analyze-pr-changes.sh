#!/bin/bash
#
# analyze-pr-changes.sh
#
# Given a Bitbucket pull-request, determine which follow-up steps need to run.
# Outputs:
#   ${ARTIFACTS_DIR}/changes.json                   - raw change list fetched from Bitbucket
#   ${ARTIFACTS_DIR}/parsed-paths-from-changes.txt  - paths parsed from changes.json (one per line, for human inspection)
#   ${ARTIFACTS_DIR}/steps.csv                      - CSV with a header row (csv_order names) and one data row (booleans)
#
# This script does NOT write summary.md or post the PR comment; summary.md is
# assembled by build-summary.sh, and posting is done by post-pr-summary.sh in
# the Jenkins post stage.
#
# Required environment variables:
#   BITBUCKET_API      - Bitbucket REST API prefix, e.g.
#                        https://code.parasoftcn.com/rest/api/latest/projects/JSC/repos/javascript-coverage
#   API_USERNAME       - Bitbucket API user name
#   API_PASSWORD       - Bitbucket API password / token
#   PR_FILE_PATH_RULES - Path-rule JSON file (default: jenkins/scripts/pr-path-rules.json)
#   CHANGE_ID          - Provided by Jenkins Multibranch; PR number. Empty or "null" for non-PR builds.
#   CHANGE_BRANCH      - Provided by Jenkins Multibranch; source branch name (used only for logging).
#   ARTIFACTS_DIR      - Output directory for artifacts (default: artifacts)
#
# Exit codes: 0 = success (including the early-exit non-PR case); non-zero = failure.
#
set -euo pipefail

ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"
PR_FILE_PATH_RULES="${PR_FILE_PATH_RULES:-jenkins/scripts/pr-path-rules.json}"
AUTO_FIX_COMMIT_MARKER="${AUTO_FIX_COMMIT_MARKER:-[jscov-auto-fix]}"

mkdir -p "${ARTIFACTS_DIR}"

# Loop-prevention guard: skip only Auto-fix (not Static Analysis) when the tip commit is the bot's own auto-fix commit, to avoid a fix/push loop.
LAST_COMMIT_SUBJECT=$(git log -1 --pretty=%s 2>/dev/null || echo '')
if [[ "${LAST_COMMIT_SUBJECT}" == "${AUTO_FIX_COMMIT_MARKER}"* ]]; then
    echo "Tip commit (\"${LAST_COMMIT_SUBJECT}\") was produced by the auto-fix bot; skipping Auto-fix this round to avoid a fix/push loop (Static Analysis will still re-run to confirm the outcome)."
    echo "true" > "${ARTIFACTS_DIR}/skip_auto_fix.txt"
else
    echo "false" > "${ARTIFACTS_DIR}/skip_auto_fix.txt"
fi

if [[ -z "${CHANGE_ID:-}" || "${CHANGE_ID:-}" == "null" ]]; then
    echo "This is not a pull-request build; no pre-analysis is required."
    # Header + default row; both are derived from csv_order so lengths always match.
    jq -r '
        (.csv_order | @csv),
        ([.csv_order[] | false] | @csv)
    ' "${PR_FILE_PATH_RULES}" > "${ARTIFACTS_DIR}/steps.csv"
    exit 0
fi

# ---------------------------------------------------------------------------

echo "---- getting changes from PR ----"
echo "CHANGE_ID=${CHANGE_ID:-}"
echo "CHANGE_BRANCH=${CHANGE_BRANCH:-}"

: "${BITBUCKET_API:?BITBUCKET_API is required}"
: "${API_USERNAME:?API_USERNAME is required}"
: "${API_PASSWORD:?API_PASSWORD is required}"

# Fetch all pages of changes from Bitbucket (recursive pagination)
START=0
LIMIT=1000
TEMP_DIR=$(mktemp -d -p .)
PAGE=0

while true; do
    PAGE_FILE="${TEMP_DIR}/page_${PAGE}.json"
    curl --fail --silent --show-error \
        -u "${API_USERNAME}:${API_PASSWORD}" \
        -H "Accept: application/json" \
        --url "${BITBUCKET_API}/pull-requests/${CHANGE_ID}/changes?limit=${LIMIT}&start=${START}" \
        -o "${PAGE_FILE}"

    PAGE=$((PAGE + 1))

    # Check if there is a next page
    NEXT_PAGE_START=$(jq -r '.nextPageStart // empty' "${PAGE_FILE}" | tr -d '\r')
    if [[ -z "${NEXT_PAGE_START}" ]]; then
        break
    fi
    START="${NEXT_PAGE_START}"
done

# Merge all pages into a single changes.json by concatenating .values arrays
jq -s '{ values: [ .[].values[] ], size: [ .[].values[] ] | length, isLastPage: true }' \
    "${TEMP_DIR}"/page_*.json > "${ARTIFACTS_DIR}/changes.json"

rm -rf "${TEMP_DIR}"

echo "-----------------------"
echo

# ---------------------------------------------------------------------------

echo "---- parsing paths from changes ----"
jq -r '.values[].path.toString' "${ARTIFACTS_DIR}/changes.json" \
    | sed 's/$/\r/' \
    > "${ARTIFACTS_DIR}/parsed-paths-from-changes.txt" || true
cat "${ARTIFACTS_DIR}/parsed-paths-from-changes.txt"
echo "-----------------------"
echo

# ---------------------------------------------------------------------------

echo "---- analyzing changes ----"
CSV_ROW=$(
    jq -r --raw-output --slurpfile rules "${PR_FILE_PATH_RULES}" '
        ($rules[0]) as $R |
        [ .values[].path.toString ] as $paths |

        # Glob -> Regex conversion (supported subset: ** / * / ? ; all other chars are literal)
        # Steps:
        #   1) Replace **, *, ? with unlikely-to-appear control-char placeholders
        #   2) Escape Oniguruma meta-characters (produce "\<char>"; note that in a jq
        #      string literal "\\" denotes a single backslash character)
        #   3) Restore placeholders back to their regex fragments
        #   4) Anchor with ^ at the start and $ at the end
        def glob2re:
          gsub("\\*\\*"; "\u0001")
          | gsub("\\*"; "\u0002")
          | gsub("\\?"; "\u0003")
          | gsub("(?<c>[][.+(){}|^$\\\\])"; "\\\(.c)")
          | gsub("\u0001"; ".*")
          | gsub("\u0002"; "[^/]*")
          | gsub("\u0003"; "[^/]")
          | "^" + . + "$";

        # A category is considered hit when any of its globs matches any changed path.
        # Pre-compile the glob list into a regex list once, so we do not translate each glob per path.
        def hit_category($cat):
          ($cat.glob // [] | map(glob2re)) as $rs |
          $paths | any(. as $p | any($rs[]; . as $re | $p | test($re)));

        # Compute the hit result for every category.
        ( $R.categories | to_entries
          | map({ key: .key, value: hit_category(.value) })
          | from_entries
        ) as $hits |

        # Emit booleans following csv_order.
        [ $R.csv_order[] as $name
          | ($R.outputs[$name].any_of // [])
          | any(.[]; $hits[.] == true)
        ] | @csv
    ' "${ARTIFACTS_DIR}/changes.json"
)

CSV_HEADER=$(jq -r '.csv_order | @csv' "${PR_FILE_PATH_RULES}")
{
    echo "${CSV_HEADER}"
    echo "${CSV_ROW}"
} > "${ARTIFACTS_DIR}/steps.csv"
echo "steps.csv header => ${CSV_HEADER}"
echo "steps.csv row    => ${CSV_ROW}"
echo "-----------------------"
echo




