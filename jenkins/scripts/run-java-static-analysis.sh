#!/usr/bin/env bash
set -euo pipefail

: "${JTEST_HOME:?JTEST_HOME is required}"
: "${DTP_URL:?DTP_URL is required}"
: "${DTP_USER:?DTP_USER is required}"
: "${DTP_PASSWORD:?DTP_PASSWORD is required}"

artifacts_dir="${ARTIFACTS_DIR:-artifacts}"
static_dir="${artifacts_dir}/static/java"
mkdir -p "$static_dir"

bash gradlew --no-daemon --no-parallel --stacktrace -i jtest \
  -I "$JTEST_HOME/integration/gradle/init.gradle" \
  -Djtest.report="target/jtest" \
  -Djtest.fail="false" \
  -Djtest.settings="jenkins/scripts/jtest.properties" \
  -Dproperty.dtp.url="${DTP_URL}" \
  -Dproperty.dtp.user="${DTP_USER}" \
  -Dproperty.dtp.password="${DTP_PASSWORD}" \
  2>&1 | tee "$static_dir/jtest.log"

if [[ ! -f target/jtest/report.xml ]]; then
    echo 'Jtest report was not generated at target/jtest/report.xml.' >&2
    exit 1
fi

violations=$(xmllint --xpath 'string(//TestedFilesDetails/Total/@total)' target/jtest/report.xml)
if [[ ! "$violations" =~ ^[0-9]+$ ]]; then
    echo 'Unable to parse the Jtest violation count.' >&2
    exit 1
fi

cp -R target/jtest "$static_dir/report"

cat >> "$artifacts_dir/summary.md" <<EOF
## Static Analysis (Java)

- Jtest found $violations violation(s)
EOF
