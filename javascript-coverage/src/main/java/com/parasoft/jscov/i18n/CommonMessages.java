package com.parasoft.jscov.i18n;

import com.parasoft.xtest.common.nls.NLS;

public final class CommonMessages extends NLS {

    static {
        NLS.initMessages(CommonMessages.class);
    }

    public static String UNSUPPORTED_COMMAND;
    public static String MISSING_REQUIRED_PARAMETER;
    public static String MISSING_VALUE_FOR_PARAMETER;
    public static String UNSPECIFIED_PARAMETER;
    public static String STATIC_COVERAGE_JSON_FILE_NOT_FOUND;
    public static String PROPERTIES_FILE_NOT_FOUND;
    public static String UNKNOWN_PARAMETERS;
    public static String UNEXPECTED_VALUE_FOR_PARAMETER;
}
