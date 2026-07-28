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
}
