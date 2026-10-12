package com.parasoft.jscov.coverage;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;

final class CoverageVersionManifestReader {

    static final String VERSION_FILE_NAME = "version.json";
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private CoverageVersionManifestReader() {
    }

    static String read(Path coverageDirectory, String missingMessage, String unreadableMessage,
            String invalidMessage) throws IOException {
        Objects.requireNonNull(coverageDirectory, NLS.getFormatted(CommonMessages.COVERAGE_DIRECTORY_MUST_NOT_BE_NULL));

        Path manifestPath = coverageDirectory.resolve(VERSION_FILE_NAME);
        if (!Files.exists(manifestPath)) {
            throw new IOException(NLS.getFormatted(missingMessage));
        }

        String manifestContent;
        try {
            manifestContent = Files.readString(manifestPath);
        } catch (IOException e) {
            throw new IOException(NLS.getFormatted(unreadableMessage), e);
        }

        JsonNode manifest;
        try {
            manifest = OBJECT_MAPPER.readTree(manifestContent);
        } catch (IOException e) {
            throw invalidManifest(invalidMessage, e.getMessage(), e);
        }
        if (manifest == null || !manifest.isObject()) {
            throw invalidManifest(invalidMessage, NLS.getFormatted(
                    CommonMessages.COVERAGE_VERSION_MANIFEST_MUST_CONTAIN_JSON_OBJECT), null);
        }

        String schemaVersion = requiredTextValue(manifest, "schemaVersion", invalidMessage);
        requiredTextValue(manifest, "toolVersion", invalidMessage);
        return schemaVersion;
    }

    private static String requiredTextValue(JsonNode manifest, String fieldName, String invalidMessage)
            throws IOException {
        JsonNode field = manifest.get(fieldName);
        if (field == null || !field.isTextual() || field.asText().isBlank()) {
            throw invalidManifest(invalidMessage, NLS.getFormatted(
                    CommonMessages.COVERAGE_VERSION_MANIFEST_FIELD_MUST_BE_NON_BLANK_STRING,
                    fieldName), null);
        }
        return field.asText();
    }

    private static IOException invalidManifest(String invalidMessage, Object details, Throwable cause) {
        String message = NLS.getFormatted(invalidMessage, details);
        return cause == null ? new IOException(message) : new IOException(message, cause);
    }
}
