#!/usr/bin/env bash
set -e

# Project-specific entry point that produces a single, merged SBOM for the
# javascript-coverage distribution. It reuses the non-project-specific building
# blocks extracted into the workspace's us/ directory:
#   - sbom_scan_java.sh : Java SBOM from the runnable jar (Anchore Syft)
#   - sbom_scan_js.sh   : JS SBOM from module sources (CycloneDX BOM)
#   - sbom_process.sh   : merge + dedup + fix + validate + upload + wiki
#
# Run this script from the repository root after `./gradlew clean dist`.
#
# Optional environment variables:
#   IS_CHENGDU - Set to "true" for Chengdu builds. Chengdu builds disable
#                the dtrack upload and wiki generation. Non-Chengdu builds enable
#                both.
#   PROFILE    - Maven profile passed to sbom-maven-plugin.

# Shared, non-project-specific SBOM scripts are extracted from the clean
# Jenkins workspace's top-level us/ directory.
# Chengdu builds only produce the merged SBOM json, while non-Chengdu builds also upload and generate the wiki.
if [ "${IS_CHENGDU}" = "true" ]; then
    SHARED_REPOSITORY_URL="ssh://git@code.parasoftcn.com:7998/jjs/jenkins-scripts.git"
    export UPLOAD_TO_DTRACK=false
    export GENERATE_WIKI=false
else
    SHARED_REPOSITORY_URL="ssh://git@trove.parasoft.com:7999/bach/code.parasoftcn.com--jjs--jenkins-scripts.git"
    export UPLOAD_TO_DTRACK=true
    export GENERATE_WIKI=true
fi
SHARED_DIR="$(pwd)/us"

git archive --remote="${SHARED_REPOSITORY_URL}" master us | tar -x

export PROJECT_NAME="JavaScript Coverage and TIA"
export SBOM_FILENAME="javascript-coverage-sbom"
export USE_SBOM_UPDATER=true
# Forward the Chengdu switch so sbom_process.sh can select the right repository.
export IS_CHENGDU
# Directory that may hold sbom-injection.xml / sbom-injection-extra.json for
# manual SBOM fixups. This is project-specific, so keep it next to this script.
export MAPPING_DIR="jenkins/scripts"

# Java: scan the runnable distribution jar (parasoft-jscov.jar), which contains
# only the Java dependencies. Scanning the jar rather than the whole dist zip
# avoids double-counting the JS components handled below.
ARCHIVE_FILE=$(find "javascript-coverage-cli/build/libs" -maxdepth 1 -name "parasoft-jscov.jar" | head -n 1)
export ARCHIVE_FILE
if [ -z "$ARCHIVE_FILE" ]; then
    echo -e "\e[31m✗ Error: parasoft-jscov.jar not found. Run './gradlew clean dist' first.\e[0m"
    exit 1
fi

# JavaScript source modules bundled into the distribution.
JS_MODULES=(
    "integration/jscov-agent"
    "integration/parasoft-istanbul-lib-instrument"
)

# Step 1: Java SBOM -> ${SBOM_FILENAME}-java.json (in the repository root)
"${SHARED_DIR}/sbom_scan_java.sh"

# Step 2: JS SBOM per module -> <module>/${SBOM_FILENAME}-js.json
JS_SBOM_FILES=()
for module in "${JS_MODULES[@]}"; do
    (
        cd "${module}"
        "${SHARED_DIR}/sbom_scan_js.sh"
    )
    JS_SBOM_FILES+=("${module}/${SBOM_FILENAME}-js.json")
done

# Step 3: Merge the Java SBOM with every JS SBOM into ${SBOM_FILENAME}.json
"${SHARED_DIR}/sbom_process.sh" "${SBOM_FILENAME}-java.json" "${JS_SBOM_FILES[@]}"

echo -e "\e[32m✓ Combined SBOM generated: ${SBOM_FILENAME}.json\e[0m"