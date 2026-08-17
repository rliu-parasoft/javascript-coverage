#!/usr/bin/env bash
set -euo pipefail

: "${JTEST_HOME:?JTEST_HOME is required}"

workspace="${WORKSPACE:-$(pwd)}"
artifacts_dir="${ARTIFACTS_DIR:-$workspace/artifacts}"
report_dir="$workspace/reports/unit-tests/java/full"
tia_report_dir="$workspace/reports/unit-tests/java/tia"
output_dir="$artifacts_dir/reports/unit-tests/java/full"
tia_output_dir="$artifacts_dir/reports/unit-tests/java/tia"

if [[ "${NEED_JAVA_TEST_FULL:-false}" == 'true' ]]; then
    mode='full'
elif [[ "${NEED_JAVA_TEST_TIA:-false}" == 'true' ]]; then
    mode='tia'
else
    echo 'No Java test execution requested.'
    exit 0
fi

mkdir -p "$artifacts_dir"

# Collect JUnit XML results from Gradle build output into target directory.
collect_junit_results() {
    local target="$1"
    local junit_dir="$workspace/javascript-coverage-cli/build/test-results/test"
    if [[ -d "$junit_dir" ]]; then
        mkdir -p "$target/junit"
        cp -R "$junit_dir"/. "$target/junit/"
    fi
}

# Collect Gradle HTML test report into target directory.
collect_html_report() {
    local target="$1"
    local html_dir="$workspace/javascript-coverage-cli/build/reports/tests/test"
    if [[ -d "$html_dir" ]]; then
        mkdir -p "$target/html"
        cp -R "$html_dir"/. "$target/html/"
    fi
}

# Append a key=value pair to the unified status file.
write_status() {
    local key="$1" value="$2"
    mkdir -p "$artifacts_dir/status"
    echo "${key}=${value}" >> "$artifacts_dir/status/all.env"
}

case "$mode" in
    full)
        mkdir -p "$report_dir" "$output_dir"
        result=passed
        if bash "$workspace/gradlew" --no-daemon --no-parallel --stacktrace -i \
            :javascript-coverage-cli:jtest-agent :javascript-coverage-cli:test jtest \
            -I "$JTEST_HOME/integration/gradle/init.gradle" \
            -Djtest.config='builtin://Unit Tests' \
            -Djtest.report="$report_dir" \
            -Djtest.settings="$workspace/jenkins/scripts/jtest.properties" \
            -Dproperty.dtp.url="${DTP_URL:-}" \
            -Dproperty.dtp.user="${DTP_USER:-}" \
            -Dproperty.dtp.password="${DTP_PASSWORD:-}" \
            --continue; then
            result=passed
        else
            result=failed
        fi
        collect_junit_results "$report_dir"
        cp -R "$report_dir"/. "$output_dir/" 2>/dev/null || true
        write_status "java_full_status" "$result"
        ;;
    tia)
        mkdir -p "$tia_report_dir" "$tia_output_dir"
        baseline_dir="$tia_report_dir/baseline"
        mkdir -p "$baseline_dir"

        # Download reference artifacts for TIA
        baseline_url='https://jenkins.parasoftcn.com/job/javascript.coverage.test/lastSuccessfulBuild/artifact/reports/unit'
        curl --fail --silent --show-error "$baseline_url/coverage.xml" -o "$baseline_dir/coverage.xml"
        curl --fail --silent --show-error "$baseline_url/report.xml" -o "$baseline_dir/report.xml"
        [[ -s "$baseline_dir/coverage.xml" && -s "$baseline_dir/report.xml" ]] \
            || { echo 'TIA baseline artifact is missing.' >&2; exit 1; }

        # Generate a complete settings file for TIA
        tia_settings="$workspace/jtestcli.properties"
        cp "$workspace/jenkins/scripts/jtest.properties" "$tia_settings"
        cat >> "$tia_settings" <<EOF

# DTP connection (appended at runtime for TIA)
dtp.url=${DTP_URL:-}
dtp.user=${DTP_USER:-}
dtp.password=${DTP_PASSWORD:-}
EOF

        result=passed
        if bash "$workspace/gradlew" --no-daemon --no-parallel --stacktrace -i \
            :javascript-coverage-cli:affectedTests :javascript-coverage-cli:test \
            -I "$JTEST_HOME/integration/gradle/init.gradle" \
            -Djtest.settings="$tia_settings" \
            -Djtest.referenceCoverageFile="$baseline_dir/coverage.xml" \
            -Djtest.referenceReportFile="$baseline_dir/report.xml" \
            -Djtest.runFailedTests=false \
            -Djtest.runModifiedTests=true \
            --continue; then
            result=passed
        else
            result=failed
        fi
        collect_junit_results "$tia_report_dir"
        collect_html_report "$tia_report_dir"
        cp -R "$tia_report_dir"/. "$tia_output_dir/" 2>/dev/null || true
        write_status "java_tia_status" "$result"
        ;;
esac
