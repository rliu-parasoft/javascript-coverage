package com.parasoft.jscov.coverage;

import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;

import java.io.IOException;
import java.nio.file.Path;

public final class RuntimeCoverageVersionManifestReader {

    private RuntimeCoverageVersionManifestReader() {
    }

    public static RuntimeCoverageSchemaVersion read(Path runtimeDataDirectory) throws IOException {
        String schemaVersion = CoverageVersionManifestReader.read(runtimeDataDirectory,
                CommonMessages.MISSING_RUNTIME_COVERAGE_VERSION_MANIFEST,
                CommonMessages.UNREADABLE_RUNTIME_COVERAGE_VERSION_MANIFEST,
                CommonMessages.INVALID_RUNTIME_COVERAGE_VERSION_MANIFEST);

        return RuntimeCoverageSchemaVersion.fromValue(schemaVersion)
                .orElseThrow(() -> new IOException(NLS.getFormatted(
                        CommonMessages.UNSUPPORTED_RUNTIME_COVERAGE_SCHEMA_VERSION,
                        schemaVersion)));
    }
}
