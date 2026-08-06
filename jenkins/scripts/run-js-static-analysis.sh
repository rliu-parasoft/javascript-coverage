#!/usr/bin/env bash
set -euo pipefail

artifacts_dir="${ARTIFACTS_DIR:-artifacts}"
static_dir="${artifacts_dir}/static/js"
mkdir -p "$static_dir"

bash gradlew --no-daemon :integration:lintReport 2>&1 | tee "$static_dir/eslint.log"

violations=0
mapfile -t reports < <(find integration -type f -path '*/build/reports/eslint/checkstyle.xml' -print)

if (( ${#reports[@]} == 0 )); then
    echo 'No ESLint Checkstyle report was generated.' >&2
    exit 1
fi

for report in "${reports[@]}"; do
    destination="$static_dir/${report#integration/}"
    mkdir -p "$(dirname "$destination")"
    cp "$report" "$destination"

    count=$(xmllint --xpath 'count(//error)' "$report")
    violations=$((violations + count))
done

cat >> "$artifacts_dir/summary.md" <<EOF
## Static Analysis (JavaScript)

- ESLint found $violations violation(s)
EOF
