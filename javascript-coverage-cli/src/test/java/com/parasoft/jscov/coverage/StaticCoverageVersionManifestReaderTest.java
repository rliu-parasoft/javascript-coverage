package com.parasoft.jscov.coverage;

import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class StaticCoverageVersionManifestReaderTest {

    @TempDir
    Path tempDir;

    @Test
    void read_rejectsNullDirectoryWithLocalizedMessage() {
        NullPointerException failure = assertThrows(NullPointerException.class,
                () -> StaticCoverageVersionManifestReader.read(null));

        assertEquals(NLS.getFormatted(CommonMessages.COVERAGE_DIRECTORY_MUST_NOT_BE_NULL), failure.getMessage());
    }

    @Test
    void read_rejectsMissingManifest() {
        IOException exception = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.MISSING_STATIC_COVERAGE_VERSION_MANIFEST),
                exception.getMessage());
    }

    @Test
    void read_rejectsUnreadableManifest() throws IOException {
        Files.createDirectory(tempDir.resolve("version.json"));

        IOException exception = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.UNREADABLE_STATIC_COVERAGE_VERSION_MANIFEST),
                exception.getMessage());
    }

    @Test
    void versionManifestSchema_isNotPackaged() {
        assertNull(StaticCoverageVersionManifestReader.class
                .getResourceAsStream("static-coverage-version.schema.json"));
    }

    @Test
    void read_returnsSupportedSchemaVersion_forValidManifest() throws IOException {
        writeManifest("""
                {
                  "schemaVersion": "1.0",
                  "toolVersion": "6.0.3-1"
                }
                """);

        assertEquals(StaticCoverageSchemaVersion.V1_0, StaticCoverageVersionManifestReader.read(tempDir));
    }

    @Test
    void read_allowsUnknownManifestFields() throws IOException {
        writeManifest("""
                {
                  "schemaVersion": "1.0",
                  "toolVersion": "6.0.3-1",
                  "futureMetadata": true
                }
                """);

        assertEquals(StaticCoverageSchemaVersion.V1_0, StaticCoverageVersionManifestReader.read(tempDir));
    }

    @Test
    void read_rejectsInvalidJson() throws IOException {
        writeManifest("{ invalid json");

        assertInvalidManifest();
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("invalidRequiredFieldManifests")
    void read_rejectsInvalidRequiredField(String scenario, String fieldName, String manifest) throws IOException {
        writeManifest(manifest);

        assertInvalidManifest(CommonMessages.COVERAGE_VERSION_MANIFEST_FIELD_MUST_BE_NON_BLANK_STRING,
                fieldName);
    }

    @Test
    void read_rejectsArrayRootManifest() throws IOException {
        writeManifest("""
            [{"schemaVersion": "1.0", "toolVersion": "6.0.3-1"}]
            """);

        assertInvalidManifest(CommonMessages.COVERAGE_VERSION_MANIFEST_MUST_CONTAIN_JSON_OBJECT);
    }

    private void writeManifest(String content) throws IOException {
        Files.writeString(tempDir.resolve("version.json"), content);
    }

    private static Stream<Arguments> invalidRequiredFieldManifests() {
        return Stream.of(
                Arguments.of("missing schemaVersion", "schemaVersion", """
                        {
                          "toolVersion": "6.0.3-1"
                        }
                        """),
                Arguments.of("missing toolVersion", "toolVersion", """
                        {
                          "schemaVersion": "1.0"
                        }
                        """),
                Arguments.of("blank schemaVersion", "schemaVersion", """
                        {
                          "schemaVersion": " ",
                          "toolVersion": "6.0.3-1"
                        }
                        """),
                Arguments.of("blank toolVersion", "toolVersion", """
                        {
                          "schemaVersion": "1.0",
                          "toolVersion": ""
                        }
                        """),
                Arguments.of("null schemaVersion", "schemaVersion", """
                        {
                          "schemaVersion": null,
                          "toolVersion": "6.0.3-1"
                        }
                        """),
                Arguments.of("null toolVersion", "toolVersion", """
                        {
                          "schemaVersion": "1.0",
                          "toolVersion": null
                        }
                        """),
                Arguments.of("non-string schemaVersion", "schemaVersion", """
                        {
                          "schemaVersion": 1,
                          "toolVersion": "6.0.3-1"
                        }
                        """),
                Arguments.of("non-string toolVersion", "toolVersion", """
                        {
                          "schemaVersion": "1.0",
                          "toolVersion": true
                        }
                        """));
    }

    private void assertInvalidManifest() {
        IOException exception = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(tempDir));

        String detailsMarker = "__DETAILS__";
        String expectedPrefix = NLS.getFormatted(CommonMessages.INVALID_STATIC_COVERAGE_VERSION_MANIFEST,
                detailsMarker);
        assertTrue(exception.getMessage().startsWith(
                expectedPrefix.substring(0, expectedPrefix.indexOf(detailsMarker))));
    }

    private void assertInvalidManifest(String detailsMessage, Object... detailsArguments) {
        IOException exception = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.INVALID_STATIC_COVERAGE_VERSION_MANIFEST,
                NLS.getFormatted(detailsMessage, detailsArguments)), exception.getMessage());
    }
}
