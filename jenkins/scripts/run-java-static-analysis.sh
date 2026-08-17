#!/usr/bin/env bash
set -euo pipefail

: "${JTEST_HOME:?JTEST_HOME is required}"
: "${DTP_URL:?DTP_URL is required}"
: "${DTP_USER:?DTP_USER is required}"
: "${DTP_PASSWORD:?DTP_PASSWORD is required}"

workspace="${WORKSPACE:-$(pwd)}"
artifacts_dir="${ARTIFACTS_DIR:-$workspace/artifacts}"
report_dir="$workspace/reports/static-analysis/java"
output_dir="$artifacts_dir/reports/static-analysis/java"
mkdir -p "$report_dir" "$output_dir"

bash "$workspace/gradlew" --no-daemon --no-parallel --stacktrace -i jtest \
    -I "$JTEST_HOME/integration/gradle/init.gradle" \
    -Djtest.config="dtp://Recommended Rules [Parasoft SOAVirt]" \
    -Djtest.report="$report_dir" \
    -Djtest.fail="false" \
    -Djtest.settings="$workspace/jenkins/scripts/jtest.properties" \
    -Dproperty.dtp.url="${DTP_URL}" \
    -Dproperty.dtp.user="${DTP_USER}" \
    -Dproperty.dtp.password="${DTP_PASSWORD}" \
    2>&1 | tee "$report_dir/jtest.log"

if [[ ! -f "$report_dir/report.xml" ]]; then
    echo "Jtest report was not generated at $report_dir/report.xml." >&2
    exit 1
fi

violations=$(xmllint --xpath 'string(//TestedFilesDetails/Total/@total)' "$report_dir/report.xml")
if [[ ! "$violations" =~ ^[0-9]+$ ]]; then
    echo 'Unable to parse the Jtest violation count.' >&2
    exit 1
fi

cp -R "$report_dir"/. "$output_dir/"

mkdir -p "$artifacts_dir/status"
echo "JAVA_SA_VIOLATIONS=$violations" >> "$artifacts_dir/status/all.env"
