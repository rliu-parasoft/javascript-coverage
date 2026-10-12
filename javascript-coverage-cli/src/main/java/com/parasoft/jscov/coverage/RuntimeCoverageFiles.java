package com.parasoft.jscov.coverage;

import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

public record RuntimeCoverageFiles(RuntimeCoverageSchemaVersion schemaVersion, List<Path> jsonFiles) {

    public static RuntimeCoverageFiles read(Path runtimeDataDirectory) throws IOException {
        RuntimeCoverageSchemaVersion version = RuntimeCoverageVersionManifestReader.read(runtimeDataDirectory);
        try (var paths = Files.walk(runtimeDataDirectory)) {
            List<Path> files = paths.filter(Files::isRegularFile)
                    .filter(path -> path.getFileName().toString().endsWith(".json"))
                    .filter(path -> !path.getFileName().toString().equals(CoverageVersionManifestReader.VERSION_FILE_NAME))
                    .sorted().toList();
            return new RuntimeCoverageFiles(version, files);
        } catch (IOException | UncheckedIOException e) {
            Throwable cause = e instanceof UncheckedIOException unchecked ? unchecked.getCause() : e;
            throw new IOException(NLS.getFormatted(CommonMessages.FAILED_TO_LIST_RUNTIME_COVERAGE_JSON_FILES,
                    runtimeDataDirectory), cause);
        }
    }
}
