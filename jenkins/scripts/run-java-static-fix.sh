#!/usr/bin/env bash
set -e

[[ -n "${BASELINE_REPORT:-}" ]] || { echo "BASELINE_REPORT is required." >&2; exit 1; }
[[ -n "${JTEST_HOME:-}" ]] || { echo "JTEST_HOME is required." >&2; exit 1; }
[[ -n "${CODEX_MODEL:-}" ]] || { echo "CODEX_MODEL is required." >&2; exit 1; }
[[ -n "${CODEX_API_KEY:-}" ]] || { echo "CODEX_API_KEY is required." >&2; exit 1; }
[[ -n "${JTEST_SETTINGS:-}" ]] || { echo "JTEST_SETTINGS is required." >&2; exit 1; }
[[ -n "${DTP_URL:-}" ]] || { echo "DTP_URL is required." >&2; exit 1; }
[[ -n "${DTP_USER:-}" ]] || { echo "DTP_USER is required." >&2; exit 1; }
[[ -n "${DTP_PASSWORD:-}" ]] || { echo "DTP_PASSWORD is required." >&2; exit 1; }
branch="${CHANGE_BRANCH:-${BRANCH_NAME:-}}"
[[ -n "$branch" ]] || { echo "CHANGE_BRANCH or BRANCH_NAME is required." >&2; exit 1; }

workspace="${WORKSPACE:-$(pwd)}"
artifacts_dir="${ARTIFACTS_DIR:-$workspace/artifacts}"
runtime_dir="$artifacts_dir/reports/static-analysis-fix/java"
mkdir -p "$runtime_dir"

status_file="$artifacts_dir/status/all.env"
JAVA_SA_VIOLATIONS=""
[[ -f "$status_file" ]] && source "$status_file"
violations="${JAVA_SA_VIOLATIONS:-$(xmllint --xpath 'string(//TestedFilesDetails/Total/@total)' "$BASELINE_REPORT")}"

if [[ "$violations" == "0" ]]; then
    echo "No Java static-analysis violations were found." > "$runtime_dir/codex_summary.md"
    exit 0
fi

pre_fix_head=$(git -C "$workspace" rev-parse HEAD)

git -C "$workspace" config user.name "JTest MCP"
git -C "$workspace" config user.email "jtest-mcp@parasoft.com"

# Codex CLI only loads MCP servers from $CODEX_HOME/config.toml, so generate it at runtime.
codex_home="$workspace/.codex"
mkdir -p "$codex_home"
cat > "$codex_home/config.toml" <<EOF
[mcp_servers.Jtest]
command = "$JTEST_HOME/integration/mcp/jtestmcp.bat"
args = []
EOF

set +e
(
    cd "$workspace"

    OPENAI_API_KEY="$CODEX_API_KEY" \
    CODEX_HOME="$codex_home" \
    WORKSPACE="$workspace" \
    ARTIFACTS_DIR="$artifacts_dir" \
    BASELINE_REPORT="$BASELINE_REPORT" \
    JTEST_SETTINGS="$JTEST_SETTINGS" \
    DTP_URL="$DTP_URL" \
    DTP_USER="$DTP_USER" \
    DTP_PASSWORD="$DTP_PASSWORD" \
    codex --ask-for-approval never --sandbox danger-full-access exec \
        --skip-git-repo-check \
        --cd "$workspace" \
        --model "$CODEX_MODEL" \
        "Follow jenkins/scripts/staticfix-instructions.md to repair the Java findings in $BASELINE_REPORT. Write outputs to artifacts/reports/static-analysis-fix/java."
)
status=$?
set -e

if [[ ! -s "$runtime_dir/codex_summary.md" ]]; then
    echo "Codex CLI ended with status $status." > "$runtime_dir/codex_summary.md"
fi

current_head=$(git -C "$workspace" rev-parse HEAD)
push_status_file="$runtime_dir/push_status.txt"

if [[ "$current_head" == "$pre_fix_head" ]]; then
    push_status="No fixes to push"
else
    echo "Pushing auto-fix commits (${pre_fix_head} -> ${current_head}) to branch ${branch}"
    git -C "$workspace" push origin "HEAD:refs/heads/${branch}"
    push_status="Fixes were committed to the pull-request"
fi
echo "$push_status" > "$push_status_file"

# fixes_failed.txt (not the stale pre-fix report.xml) is the authoritative post-fix signal.
fixes_failed_file="$runtime_dir/fixes_failed.txt"
if [[ ! -f "$fixes_failed_file" ]]; then
    echo "Missing fixes_failed.txt from auto-fix run; cannot confirm full resolution." >&2
    status=1
else
    failed_count=$(tr -d '[:space:]' < "$fixes_failed_file")
    if [[ ! "$failed_count" =~ ^[0-9]+$ ]]; then
        echo "Invalid fixes_failed.txt content: '$failed_count'" >&2
        status=1
    elif (( failed_count > 0 )); then
        echo "$failed_count violation(s) could not be auto-fixed." >&2
        status=1
    fi
fi

exit "$status"