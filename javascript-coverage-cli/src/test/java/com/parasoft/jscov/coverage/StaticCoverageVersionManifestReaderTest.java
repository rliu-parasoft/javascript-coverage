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
    void read_defaultsToVersion1_0_whenManifestIsAbsent() throws IOException {
        assertEquals(StaticCoverageSchemaVersion.V1_0, StaticCoverageVersionManifestReader.read(tempDir));
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

        IOException exception = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(tempDir));

        assertTrue(exception.getMessage().startsWith(
                NLS.getFormatted(CommonMessages.INVALID_STATIC_COVERAGE_VERSION_MANIFEST, "").trim()));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("invalidRequiredFieldManifests")
    void read_rejectsInvalidRequiredField(String scenario, String manifest) throws IOException {
        writeManifest(manifest);

        assertInvalidManifest();
    }

    @Test
    void read_rejectsArrayRootManifest() throws IOException {
        writeManifest("""
            [{"schemaVersion": "1.0", "toolVersion": "6.0.3-1"}]
            """);

        IOException exception = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(tempDir));

        assertTrue(exception.getMessage().contains("manifest must be a JSON object"));
    }

    private void writeManifest(String content) throws IOException {
        Files.writeString(tempDir.resolve("version.json"), content);
    }

    private static Stream<Arguments> invalidRequiredFieldManifests() {
        return Stream.of(
                Arguments.of("missing schemaVersion", """
                        {
                          "toolVersion": "6.0.3-1"
                        }
                        """),
                Arguments.of("missing toolVersion", """
                        {
                          "schemaVersion": "1.0"
                        }
                        """),
                Arguments.of("blank schemaVersion", """
                        {
                          "schemaVersion": " ",
                          "toolVersion": "6.0.3-1"
                        }
                        """),
                Arguments.of("blank toolVersion", """
                        {
                          "schemaVersion": "1.0",
                          "toolVersion": ""
                        }
                        """),
                Arguments.of("null schemaVersion", """
                        {
                          "schemaVersion": null,
                          "toolVersion": "6.0.3-1"
                        }
                        """),
                Arguments.of("null toolVersion", """
                        {
                          "schemaVersion": "1.0",
                          "toolVersion": null
                        }
                        """),
                Arguments.of("non-string schemaVersion", """
                        {
                          "schemaVersion": 1,
                          "toolVersion": "6.0.3-1"
                        }
                        """),
                Arguments.of("non-string toolVersion", """
                        {
                          "schemaVersion": "1.0",
                          "toolVersion": true
                        }
                        """));
    }

    private void assertInvalidManifest() {
        IOException exception = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(tempDir));

        assertTrue(exception.getMessage().startsWith(
                NLS.getFormatted(CommonMessages.INVALID_STATIC_COVERAGE_VERSION_MANIFEST, "").trim()));
    }
}
