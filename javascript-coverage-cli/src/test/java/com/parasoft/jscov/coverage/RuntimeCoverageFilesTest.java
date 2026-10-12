package com.parasoft.jscov.coverage;

import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class RuntimeCoverageFilesTest {

    @TempDir
    Path tempDir;

    @Test
    void read_validatesManifestBeforeEnumeratingFiles() {
        Path missingRoot = tempDir.resolve("missing-root");

        IOException failure = assertThrows(IOException.class, () -> RuntimeCoverageFiles.read(missingRoot));

        assertEquals(NLS.getFormatted(CommonMessages.MISSING_RUNTIME_COVERAGE_VERSION_MANIFEST),
                failure.getMessage());
    }

    @Test
    void read_discoversSortedNestedSessionFilesAndExcludesManifests() throws IOException {
        writeManifest(tempDir, "1.0");
        Path userDirectory = Files.createDirectories(tempDir.resolve("__default__"));
        Path laterSession = Files.writeString(userDirectory.resolve("z-session.json"), "{}");
        Path earlierSession = Files.writeString(userDirectory.resolve("a-session.json"), "{}");
        Path rootCoverage = Files.writeString(tempDir.resolve("z-root.json"), "{}");
        writeManifest(userDirectory, "2.0");
        Files.writeString(userDirectory.resolve("notes.txt"), "ignored");
        Files.writeString(userDirectory.resolve("upper.JSON"), "{}");
        Files.createDirectory(userDirectory.resolve("directory.json"));

        RuntimeCoverageFiles result = RuntimeCoverageFiles.read(tempDir);

        assertEquals(RuntimeCoverageSchemaVersion.V1_0, result.schemaVersion());
        assertEquals(List.of(earlierSession, laterSession, rootCoverage), result.jsonFiles());
    }

    @Test
    void read_returnsEmptyFilesWhenOnlyRootManifestExists() throws IOException {
        writeManifest(tempDir, "1.0");

        RuntimeCoverageFiles result = RuntimeCoverageFiles.read(tempDir);

        assertEquals(RuntimeCoverageSchemaVersion.V1_0, result.schemaVersion());
        assertEquals(List.of(), result.jsonFiles());
    }

    @Test
    void read_rejectsMissingRootManifestDespiteNestedManifest() throws IOException {
        writeManifest(Files.createDirectories(tempDir.resolve("__default__")), "1.0");

        IOException failure = assertThrows(IOException.class, () -> RuntimeCoverageFiles.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.MISSING_RUNTIME_COVERAGE_VERSION_MANIFEST),
                failure.getMessage());
    }

    @Test
    void read_rejectsUnsupportedRootSchemaDespiteSupportedNestedManifest() throws IOException {
        writeManifest(tempDir, "2.0");
        writeManifest(Files.createDirectories(tempDir.resolve("__default__")), "1.0");

        IOException failure = assertThrows(IOException.class, () -> RuntimeCoverageFiles.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.UNSUPPORTED_RUNTIME_COVERAGE_SCHEMA_VERSION, "2.0"),
                failure.getMessage());
    }

    @Test
    void read_rejectsInvalidRootManifestBeforeReturningSessionFiles() throws IOException {
        Files.writeString(tempDir.resolve("version.json"), "{}");
        Files.writeString(tempDir.resolve("session.json"), "{}");

        IOException failure = assertThrows(IOException.class, () -> RuntimeCoverageFiles.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.INVALID_RUNTIME_COVERAGE_VERSION_MANIFEST,
                NLS.getFormatted(CommonMessages.COVERAGE_VERSION_MANIFEST_FIELD_MUST_BE_NON_BLANK_STRING,
                        "schemaVersion")), failure.getMessage());
    }

    @Test
    void read_rejectsNullDirectoryWithLocalizedMessage() {
        NullPointerException failure = assertThrows(NullPointerException.class,
                () -> RuntimeCoverageFiles.read(null));

        assertEquals(NLS.getFormatted(CommonMessages.COVERAGE_DIRECTORY_MUST_NOT_BE_NULL), failure.getMessage());
    }

    private void writeManifest(Path directory, String schemaVersion) throws IOException {
        Files.writeString(directory.resolve("version.json"),
                "{\"schemaVersion\":\"" + schemaVersion + "\",\"toolVersion\":\"1.0.0\"}");
    }
}
