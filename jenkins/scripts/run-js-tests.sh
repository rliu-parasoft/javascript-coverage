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

    cp -R "$rpt_dir"/. "$out_dir/" 2>/dev/null || true
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
        write_status "js_full_status" "$result"
        if [[ "$result" == "failed" ]]; then exit 1; fi
        ;;
    tia)
        mkdir -p "$tia_report_dir" "$tia_output_dir"
        # TODO(JSC-62): JSCov TIA is not available; falling back to full test execution.
        result=passed
        bash "$workspace/gradlew" --no-daemon :integration:test || result=failed
        collect_and_archive "$tia_report_dir" "$tia_output_dir"
        write_status "js_tia_status" "$result"
        if [[ "$result" == "failed" ]]; then exit 1; fi
        ;;
esac
