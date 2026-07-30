package com.parasoft.jscov.i18n;

import com.parasoft.xtest.common.nls.NLS;

public final class CommonMessages extends NLS {

    static {
        NLS.initMessages(CommonMessages.class);
    }

    public static String TESTMAP_UNSUPPORTED_MESSAGE;
    public static String COMPARE_UNSUPPORTED_MESSAGE;
    public static String INVALID_APPLICATION_DIRECTORY_MESSAGE;
    public static String APPLICATION_PARAMETER_DESCRIPTION;
    public static String NO_ISTANBUL_JSON_FILES_FOUND;
    public static String PARSING_ISTANBUL_JSON_FILE;
    public static String FAILED_TO_PARSE_ISTANBUL_JSON;
    public static String FAILED_TO_LIST_ISTANBUL_JSON_FILES;
    public static String SKIPPING_DUPLICATE_JSON_FILES;
    public static String FAILED_TO_CREATE_ITESTABLEINPUT_FROM_PROPERTIES;
    public static String NO_VALID_ISTANBUL_JSON_FILES_FOUND_IN_DIRECTORY;
    public static String INVALID_ISTANBUL_COVERAGE_JSON;
}
