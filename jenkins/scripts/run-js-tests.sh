#!/usr/bin/env bash
set -euo pipefail

workspace="${WORKSPACE:-$(pwd)}"
artifacts_dir="${ARTIFACTS_DIR:-$workspace/artifacts}"
report_dir="$workspace/reports/unit-tests/js/full"
tia_report_dir="$workspace/reports/unit-tests/js/tia"
output_dir="$artifacts_dir/reports/unit-tests/js/full"
tia_output_dir="$artifacts_dir/reports/unit-tests/js/tia"

if [[ "${NEED_JS_TEST_FULL:-false}" == 'true' ]]; then
    mode='full'
elif [[ "${NEED_JS_TEST_TIA:-false}" == 'true' ]]; then
    mode='tia'
else
    echo 'No JavaScript test execution requested.'
    exit 0
fi

mkdir -p "$artifacts_dir"

# mocha's built-in "xunit" reporter (used by parasoft-istanbul-lib-instrument)
# emits a non-standard `file="..."` attribute on <testcase> elements. The
# Jenkins xunit plugin's JUnit parser validates against a strict JUnit XSD
# that rejects this attribute (cvc-complex-type.3.2.2), so strip it before
# the reports are archived/consumed.Mocha's newer xunit reporter adds a non-standard file attribute to <testcase> elements, which fails Jenkins' strict JUnit validation, so it must be stripped before archiving.
sanitize_junit_reports() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    find "$dir" -type f -name '*.xml' -print0 \
        | xargs -0 -r sed -i -E 's/(<testcase\b[^>]*) file="[^"]*"/\1/g'
}

# Collect test/coverage results from integration build outputs and archive to artifacts.
collect_and_archive() {
    local rpt_dir="$1" out_dir="$2"

    for module_dir in "$workspace"/integration/*/; do
        [[ -d "$module_dir" ]] || continue
        local module_name
        module_name=$(basename "$module_dir")

        # Test results
        local test_results="$module_dir/build/test-results"
        if [[ -d "$test_results" ]]; then
            mkdir -p "$rpt_dir/$module_name"
            cp -R "$test_results"/. "$rpt_dir/$module_name/"
        fi

        # Coverage
        local coverage="$module_dir/build/reports/coverage"
        if [[ -f "$coverage/clover.xml" ]]; then
            mkdir -p "$rpt_dir/$module_name/coverage"
            cp "$coverage/clover.xml" "$rpt_dir/$module_name/coverage/"
        fi
    done

    sanitize_junit_reports "$rpt_dir"

    cp -R "$rpt_dir"/. "$out_dir/" 2>/dev/null || true
}

# Detect test failures by scanning collected JUnit XML reports.
# Returns 1 if any testsuite/testsuites element reports failures>0 or errors>0.
# Returns 0 when no XML files exist or all reports are clean, so callers can
# defer to the Gradle exit code in that case.
detect_test_failures() {
    local rpt_dir="$1"
    [[ -d "$rpt_dir" ]] || return 0
    if find "$rpt_dir" -type f -name '*.xml' -print0 2>/dev/null \
        | xargs -0 -r grep -lE '(failures|errors)="[1-9][0-9]*"' >/dev/null; then
        return 1
    fi
    return 0
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
        bash "$workspace/gradlew" --no-daemon :integration:test || result=failed
        collect_and_archive "$report_dir" "$output_dir"
        detect_test_failures "$report_dir" || result=failed
        write_status "js_full_status" "$result"
        if [[ "$result" == "failed" ]]; then exit 1; fi
        ;;
    tia)
        mkdir -p "$tia_report_dir" "$tia_output_dir"
        # TODO(JSC-62): JSCov TIA is not available; falling back to full test execution.
        result=passed
        bash "$workspace/gradlew" --no-daemon :integration:test || result=failed
        collect_and_archive "$tia_report_dir" "$tia_output_dir"
        detect_test_failures "$tia_report_dir" || result=failed
        write_status "js_tia_status" "$result"
        if [[ "$result" == "failed" ]]; then exit 1; fi
        ;;
esac
