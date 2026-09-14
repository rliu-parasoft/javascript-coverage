#!/usr/bin/env bash
# Assemble the final summary.md from status files.
set -euo pipefail

workspace="${WORKSPACE:-$(pwd)}"
artifacts_dir="${ARTIFACTS_DIR:-$workspace/artifacts}"
status_file="$artifacts_dir/status/all.env"
summary_file="$artifacts_dir/summary.md"
static_fix_dir="$artifacts_dir/reports/static-analysis-fix/java"

JAVA_SA_VIOLATIONS=""
JS_SA_VIOLATIONS=""
java_tia_status=""
java_full_status=""
js_tia_status=""
js_full_status=""
[[ -f "$status_file" ]] && source "$status_file"

pass_fail() { [[ "$1" == passed ]] && echo 'Passed' || echo '**Failed**'; }

{
    echo '# PR Build Summary'
    echo
    echo '## Static Analysis'

    if [[ -n "$JAVA_SA_VIOLATIONS" ]]; then
        echo "- Java (Jtest): **${JAVA_SA_VIOLATIONS}** violation(s) found"
    elif [[ "${NEED_JAVA_SA:-}" == "true" ]]; then
        # Required but no violation count was recorded: the analysis tool itself failed.
        echo '- Java (Jtest): **Failed to run** (see build log for details)'
    else
        echo '- Java (Jtest): Skipped'
    fi

    if [[ -n "$JS_SA_VIOLATIONS" ]]; then
        echo "- JavaScript (ESLint): **${JS_SA_VIOLATIONS}** violation(s)"
    else
        echo '- JavaScript (ESLint): Skipped'
    fi
    echo
} >> "$summary_file"

if [[ -s "$static_fix_dir/codex_summary.md" ]]; then
    {
        echo '## Static Analysis (Auto-Fix)'
        echo
        sed '1{/^#\+ /d}' "$static_fix_dir/codex_summary.md"
        echo
        if [[ -s "$static_fix_dir/push_status.txt" ]]; then
            echo "- $(<"$static_fix_dir/push_status.txt")"
        else
            echo '- No fixes to push'
        fi

        if [[ -s "$static_fix_dir/fixes_failed.txt" ]]; then
            remaining=$(tr -d '[:space:]' < "$static_fix_dir/fixes_failed.txt")
            if [[ "$remaining" =~ ^[0-9]+$ ]] && (( remaining > 0 )); then
                echo "- **Warning: ${remaining} Java static-analysis violation(s) could not be fixed.**"
            fi
        fi
        echo
    } >> "$summary_file"
fi

{
    echo '## Test Execution'

    if [[ -n "$java_tia_status" || -n "$java_full_status" ]]; then
        echo '- Java (Jtest)'
        [[ -n "$java_tia_status" ]] && echo "  - TIA: $(pass_fail "$java_tia_status")"
        [[ -n "$java_full_status" ]] && echo "  - Full suite: $(pass_fail "$java_full_status")"
    else
        echo '- Java (Jtest): Skipped'
    fi

    if [[ -n "$js_tia_status" || -n "$js_full_status" ]]; then
        echo '- JavaScript'
        [[ -n "$js_full_status" ]] && echo "  - Full suite: $(pass_fail "$js_full_status")"
        [[ -n "$js_tia_status" ]] && echo "  - TIA: $(pass_fail "$js_tia_status") (Full suite temporarily)"
    else
        echo '- JavaScript: Skipped'
    fi
} >> "$summary_file"

echo "summary.md assembled at $summary_file"
