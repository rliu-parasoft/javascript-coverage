#!/usr/bin/env bash
# build-summary.sh — Assemble the final summary.md from status files.
set -euo pipefail

workspace="${WORKSPACE:-$(pwd)}"
artifacts_dir="${ARTIFACTS_DIR:-$workspace/artifacts}"
status_file="$artifacts_dir/status/all.env"
summary_file="$artifacts_dir/summary.md"

# Load all status variables
JAVA_SA_VIOLATIONS=""
JS_SA_VIOLATIONS=""
java_tia_status=""
java_full_status=""
js_tia_status=""
js_full_status=""
[[ -f "$status_file" ]] && source "$status_file"

# Append structured execution results below the analysis table.
echo '' >> "$summary_file"

# ---------------------------------------------------------------------------
# Static Analysis
# ---------------------------------------------------------------------------
echo '**Static Analysis**' >> "$summary_file"

if [[ -n "$JAVA_SA_VIOLATIONS" ]]; then
    if (( JAVA_SA_VIOLATIONS == 1 )); then
        echo "- Java (Jtest): **1** violation" >> "$summary_file"
    elif (( JAVA_SA_VIOLATIONS > 1 )); then
        echo "- Java (Jtest): **$JAVA_SA_VIOLATIONS** violations" >> "$summary_file"
    else
        echo "- Java (Jtest): 0 violations" >> "$summary_file"
    fi
else
    echo "- Java (Jtest): Skipped" >> "$summary_file"
fi

if [[ -n "$JS_SA_VIOLATIONS" ]]; then
    if (( JS_SA_VIOLATIONS == 1 )); then
        echo "- JavaScript (ESLint): **1** violation" >> "$summary_file"
    elif (( JS_SA_VIOLATIONS > 1 )); then
        echo "- JavaScript (ESLint): **$JS_SA_VIOLATIONS** violations" >> "$summary_file"
    else
        echo "- JavaScript (ESLint): 0 violations" >> "$summary_file"
    fi
else
    echo "- JavaScript (ESLint): Skipped" >> "$summary_file"
fi

echo '' >> "$summary_file"

# ---------------------------------------------------------------------------
# Test Execution
# ---------------------------------------------------------------------------
echo '**Test Execution**' >> "$summary_file"

if [[ -n "$java_tia_status" || -n "$java_full_status" ]]; then
    echo '- Java (Jtest)' >> "$summary_file"
    [[ -n "$java_tia_status" ]] && echo "  - TIA: $( [[ $java_tia_status == passed ]] && echo 'Passed' || echo '**Failed**' )" >> "$summary_file"
    [[ -n "$java_full_status" ]] && echo "  - Full suite: $( [[ $java_full_status == passed ]] && echo 'Passed' || echo '**Failed**' )" >> "$summary_file"
else
    echo '- Java (Jtest): Skipped' >> "$summary_file"
fi

if [[ -n "$js_tia_status" || -n "$js_full_status" ]]; then
    echo '- JavaScript' >> "$summary_file"
    [[ -n "$js_full_status" ]] && echo "  - Full suite: $( [[ $js_full_status == passed ]] && echo 'Passed' || echo '**Failed**' )" >> "$summary_file"
    [[ -n "$js_tia_status" ]] && echo "  - TIA: $( [[ $js_tia_status == passed ]] && echo 'Passed' || echo '**Failed**' ) (Full suite temporarily)" >> "$summary_file"
else
    echo '- JavaScript: Skipped' >> "$summary_file"
fi

echo "summary.md assembled at $summary_file"
