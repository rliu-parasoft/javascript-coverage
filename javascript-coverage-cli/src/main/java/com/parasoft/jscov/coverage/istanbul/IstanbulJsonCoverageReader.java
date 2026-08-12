package com.parasoft.jscov.coverage.istanbul;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto;
import com.networknt.schema.Error;
import com.networknt.schema.InputFormat;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.dialect.Dialects;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;
import com.parasoft.xtest.logging.internal.PathValidationUtil;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Objects;

public final class IstanbulJsonCoverageReader
{
    private static final String STATIC_COVERAGE_SCHEMA_RESOURCE = "static-istanbul-coverage.schema.json";
    private static final Schema STATIC_COVERAGE_SCHEMA = loadsCoverageSchema(STATIC_COVERAGE_SCHEMA_RESOURCE);
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    public static IstanbulSourceFileCoverageDto read(Path jsonFilePath) throws IOException
    {
        Objects.requireNonNull(jsonFilePath, "jsonFilePath must not be null");

        String json = Files.readString(jsonFilePath, StandardCharsets.UTF_8);
        String prevalidatedJson = PathValidationUtil.canonicalize(json);
        List<Error> validationErrors = STATIC_COVERAGE_SCHEMA.validate(prevalidatedJson, InputFormat.JSON);
        if (!validationErrors.isEmpty()) {
            String message = NLS.getFormatted(CommonMessages.INVALID_ISTANBUL_COVERAGE_JSON, jsonFilePath, validationErrors);
            throw new IOException(message);
        }

        return OBJECT_MAPPER.readValue(json, IstanbulSourceFileCoverageDto.class);
    }

    private static Schema loadsCoverageSchema(String schemaPath)
    {
        try (InputStream schemaStream = IstanbulJsonCoverageReader.class.getResourceAsStream(schemaPath)) {
            if (schemaStream == null) {
                throw new IllegalStateException("Istanbul coverage JSON schema resource not found: " + schemaPath);
            }
            String schemaJson = new String(schemaStream.readAllBytes(), StandardCharsets.UTF_8);
            return SchemaRegistry.withDialect(Dialects.getDraft202012()).getSchema(schemaJson, InputFormat.JSON);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load Istanbul coverage JSON schema: " + schemaPath, e);
        }
    }
}
