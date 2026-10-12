package com.parasoft.jscov.i18n;

import com.parasoft.xtest.common.nls.NLS;

public final class CommonMessages extends NLS {

    static {
        NLS.initMessages(CommonMessages.class);
    }

    public static String TESTMAP_UNSUPPORTED_MESSAGE;
    public static String COMPARE_UNSUPPORTED_MESSAGE;
    public static String INVALID_APPLICATION_DIRECTORY_MESSAGE;
    public static String MISSING_STATIC_COVERAGE_DIRECTORY_MESSAGE;
    public static String APPLICATION_PARAMETER_DESCRIPTION;
    public static String NO_STATIC_COVERAGE_JSON_FILES_FOUND;
    public static String PARSING_STATIC_COVERAGE_JSON_FILE;
    public static String FAILED_TO_PARSE_STATIC_COVERAGE_JSON;
    public static String FAILED_TO_LIST_STATIC_COVERAGE_JSON_FILES;
    public static String SKIPPED_DUPLICATE_JSON_FILES;
    public static String FAILED_TO_CREATE_ITESTABLEINPUT_FROM_PROPERTIES;
    public static String NO_VALID_STATIC_COVERAGE_JSON_FILES_FOUND_IN_DIRECTORY;
    public static String INVALID_STATIC_COVERAGE_JSON;
    public static String COVERAGE_DIRECTORY_MUST_NOT_BE_NULL;
    public static String COVERAGE_VERSION_MANIFEST_MUST_CONTAIN_JSON_OBJECT;
    public static String COVERAGE_VERSION_MANIFEST_FIELD_MUST_BE_NON_BLANK_STRING;
    public static String FAILED_TO_LIST_RUNTIME_COVERAGE_JSON_FILES;
    public static String INVALID_RUNTIME_COVERAGE_VERSION_MANIFEST;
    public static String MISSING_RUNTIME_COVERAGE_VERSION_MANIFEST;
    public static String UNREADABLE_RUNTIME_COVERAGE_VERSION_MANIFEST;
    public static String UNSUPPORTED_RUNTIME_COVERAGE_SCHEMA_VERSION;
    public static String INVALID_STATIC_COVERAGE_VERSION_MANIFEST;
    public static String MISSING_STATIC_COVERAGE_VERSION_MANIFEST;
    public static String UNREADABLE_STATIC_COVERAGE_VERSION_MANIFEST;
    public static String UNSUPPORTED_STATIC_COVERAGE_SCHEMA_VERSION;
    public static String SKIPPED_STATIC_COVERAGE_SESSION;
    public static String SKIPPED_LOWER_STATIC_COVERAGE_SCHEMA_VERSION;
    public static String REPLACED_LOWER_STATIC_COVERAGE_SCHEMA_VERSION;
}
