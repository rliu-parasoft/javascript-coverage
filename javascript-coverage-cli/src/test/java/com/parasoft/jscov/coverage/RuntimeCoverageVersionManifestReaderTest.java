package com.parasoft.jscov.coverage;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.junit.jupiter.params.provider.ValueSource;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;

class RuntimeCoverageVersionManifestReaderTest {

    @TempDir
    Path tempDir;

    @Test
    void read_returnsSupportedSchemaVersion() throws IOException {
        writeManifest("{\"schemaVersion\":\"1.0\",\"toolVersion\":\"1.0.0\"}");

        assertEquals(RuntimeCoverageSchemaVersion.V1_0, RuntimeCoverageVersionManifestReader.read(tempDir));
    }

    @Test
    void read_allowsUnknownManifestFields() throws IOException {
        writeManifest("{\"schemaVersion\":\"1.0\",\"toolVersion\":\"1.0.0\",\"futureMetadata\":true}");

        assertEquals(RuntimeCoverageSchemaVersion.V1_0, RuntimeCoverageVersionManifestReader.read(tempDir));
    }

    @Test
    void read_rejectsMissingManifest() {
        IOException failure = assertThrows(IOException.class,
                () -> RuntimeCoverageVersionManifestReader.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.MISSING_RUNTIME_COVERAGE_VERSION_MANIFEST),
                failure.getMessage());
    }

    @Test
    void read_rejectsDirectoryManifestWithPreservedCause() throws IOException {
        Files.createDirectory(tempDir.resolve("version.json"));

        IOException failure = assertThrows(IOException.class,
                () -> RuntimeCoverageVersionManifestReader.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.UNREADABLE_RUNTIME_COVERAGE_VERSION_MANIFEST),
                failure.getMessage());
        assertInstanceOf(IOException.class, failure.getCause());
    }

    @Test
    void read_rejectsInvalidJsonWithPreservedCause() throws IOException {
        writeManifest("{ invalid json");

        IOException failure = assertThrows(IOException.class,
                () -> RuntimeCoverageVersionManifestReader.read(tempDir));

        JsonProcessingException cause = assertInstanceOf(JsonProcessingException.class, failure.getCause());
        assertEquals(NLS.getFormatted(CommonMessages.INVALID_RUNTIME_COVERAGE_VERSION_MANIFEST,
                cause.getMessage()), failure.getMessage());
    }

    @ParameterizedTest
    @ValueSource(strings = {"", " ", "[]", "null", "true", "7", "\"text\""})
    void read_rejectsNonObjectManifest(String manifest) throws IOException {
        writeManifest(manifest);

        assertInvalidManifest(CommonMessages.COVERAGE_VERSION_MANIFEST_MUST_CONTAIN_JSON_OBJECT);
    }

    @ParameterizedTest(name = "{0}: {1}")
    @MethodSource("invalidRequiredFieldManifests")
    void read_rejectsInvalidRequiredField(String fieldName, String scenario, String manifest) throws IOException {
        writeManifest(manifest);

        assertInvalidManifest(CommonMessages.COVERAGE_VERSION_MANIFEST_FIELD_MUST_BE_NON_BLANK_STRING,
                fieldName);
    }

    @ParameterizedTest
    @ValueSource(strings = {"2.0", "1", " 1.0 "})
    void read_rejectsUnsupportedSchemaVersion(String version) throws IOException {
        writeManifest("{\"schemaVersion\":\"" + version + "\",\"toolVersion\":\"1.0.0\"}");

        IOException failure = assertThrows(IOException.class,
                () -> RuntimeCoverageVersionManifestReader.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.UNSUPPORTED_RUNTIME_COVERAGE_SCHEMA_VERSION, version),
                failure.getMessage());
    }

    @Test
    void read_rejectsNullDirectoryWithLocalizedMessage() {
        NullPointerException failure = assertThrows(NullPointerException.class,
                () -> RuntimeCoverageVersionManifestReader.read(null));

        assertEquals(NLS.getFormatted(CommonMessages.COVERAGE_DIRECTORY_MUST_NOT_BE_NULL), failure.getMessage());
    }

    private void writeManifest(String manifest) throws IOException {
        Files.writeString(tempDir.resolve("version.json"), manifest);
    }

    private void assertInvalidManifest(String detailsMessage, Object... arguments) {
        IOException failure = assertThrows(IOException.class,
                () -> RuntimeCoverageVersionManifestReader.read(tempDir));

        assertEquals(NLS.getFormatted(CommonMessages.INVALID_RUNTIME_COVERAGE_VERSION_MANIFEST,
                NLS.getFormatted(detailsMessage, arguments)), failure.getMessage());
    }

    private static Stream<Arguments> invalidRequiredFieldManifests() {
        return Stream.of("schemaVersion", "toolVersion").flatMap(fieldName -> {
            String otherField = fieldName.equals("schemaVersion") ? "toolVersion" : "schemaVersion";
            String otherValue = fieldName.equals("schemaVersion") ? "1.0.0" : "1.0";
            String prefix = "{\"" + otherField + "\":\"" + otherValue + "\"";
            return Stream.of(
                    Arguments.of(fieldName, "missing", prefix + "}"),
                    Arguments.of(fieldName, "null", prefix + ",\"" + fieldName + "\":null}"),
                    Arguments.of(fieldName, "empty", prefix + ",\"" + fieldName + "\":\"\"}"),
                    Arguments.of(fieldName, "blank", prefix + ",\"" + fieldName + "\":\" \"}"),
                    Arguments.of(fieldName, "number", prefix + ",\"" + fieldName + "\":1}"),
                    Arguments.of(fieldName, "boolean", prefix + ",\"" + fieldName + "\":true}"),
                    Arguments.of(fieldName, "array", prefix + ",\"" + fieldName + "\":[]}"),
                    Arguments.of(fieldName, "object", prefix + ",\"" + fieldName + "\":{}}"));
        });
    }
}
