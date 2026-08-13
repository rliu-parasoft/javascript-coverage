package com.parasoft.jscov.coverage;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Objects;

public final class StaticCoverageVersionManifestReader {

    private static final String VERSION_FILE_NAME = "version.json";
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    public static StaticCoverageSchemaVersion read(Path sessionDirectory) throws IOException {
        Objects.requireNonNull(sessionDirectory, "sessionDirectory must not be null");

        Path manifestPath = sessionDirectory.resolve(VERSION_FILE_NAME);
        if (!Files.exists(manifestPath)) {
            return StaticCoverageSchemaVersion.V1_0;
        }

        JsonNode manifest;
        try {
            manifest = OBJECT_MAPPER.readTree(Files.readString(manifestPath));
        } catch (IOException e) {
            throw invalidManifest(e.getMessage(), e);
        }
        if (manifest == null || !manifest.isObject()) {
            throw invalidManifest("manifest must be a JSON object", null);
        }

        String schemaVersion = requiredTextValue(manifest, "schemaVersion");
        requiredTextValue(manifest, "toolVersion");

        return StaticCoverageSchemaVersion.fromValue(schemaVersion)
                .orElseThrow(() -> new IOException(NLS.getFormatted(
                        CommonMessages.UNSUPPORTED_STATIC_COVERAGE_SCHEMA_VERSION,
                        schemaVersion)));
    }

    private static String requiredTextValue(JsonNode manifest, String fieldName)
            throws IOException {
        JsonNode field = manifest.get(fieldName);
        if (field == null || !field.isTextual() || field.asText().isBlank()) {
            throw invalidManifest(fieldName + " must be a non-blank string", null);
        }
        return field.asText();
    }

    private static IOException invalidManifest(Object details, Throwable cause) {
        String message = NLS.getFormatted(CommonMessages.INVALID_STATIC_COVERAGE_VERSION_MANIFEST, details);
        return cause == null ? new IOException(message) : new IOException(message, cause);
    }
}
