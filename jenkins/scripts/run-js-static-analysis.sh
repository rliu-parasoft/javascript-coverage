#!/usr/bin/env bash
set -euo pipefail

workspace="${WORKSPACE:-$(pwd)}"
artifacts_dir="${ARTIFACTS_DIR:-$workspace/artifacts}"
report_dir="$workspace/reports/static-analysis/js"
output_dir="$artifacts_dir/reports/static-analysis/js"
mkdir -p "$report_dir" "$output_dir"

bash "$workspace/gradlew" --no-daemon :integration:lintReport 2>&1 | tee "$report_dir/eslint.log"

violations=0
found=0

for module_dir in "$workspace"/integration/*/; do
    [[ -d "$module_dir" ]] || continue
    module_name=$(basename "$module_dir")

    report="$module_dir/build/reports/eslint/checkstyle.xml"
    [[ -f "$report" ]] || continue
    found=$((found + 1))

    count=$(xmllint --xpath 'count(//error)' "$report")
    violations=$((violations + count))

    mkdir -p "$report_dir/$module_name"
    cp "$report" "$report_dir/$module_name/"
done

if (( found == 0 )); then
    echo 'No ESLint Checkstyle report was generated.' >&2
    exit 1
fi

cp -R "$report_dir"/. "$output_dir/"

mkdir -p "$artifacts_dir/status"
echo "JS_SA_VIOLATIONS=$violations" >> "$artifacts_dir/status/all.env"
