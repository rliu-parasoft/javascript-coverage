package com.parasoft.jscov.coverage;

import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;

import java.io.IOException;
import java.nio.file.Path;

public final class StaticCoverageVersionManifestReader {

    public static StaticCoverageSchemaVersion read(Path sessionDirectory) throws IOException {
        String schemaVersion = CoverageVersionManifestReader.read(sessionDirectory,
                CommonMessages.MISSING_STATIC_COVERAGE_VERSION_MANIFEST,
                CommonMessages.UNREADABLE_STATIC_COVERAGE_VERSION_MANIFEST,
                CommonMessages.INVALID_STATIC_COVERAGE_VERSION_MANIFEST);

        return StaticCoverageSchemaVersion.fromValue(schemaVersion)
                .orElseThrow(() -> new IOException(NLS.getFormatted(
                        CommonMessages.UNSUPPORTED_STATIC_COVERAGE_SCHEMA_VERSION,
                        schemaVersion)));
    }
}
