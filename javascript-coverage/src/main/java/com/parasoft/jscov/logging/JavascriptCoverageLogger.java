package com.parasoft.jscov.logging;

import com.parasoft.xtest.logging.api.ParasoftLevel;
import com.parasoft.xtest.logging.api.ParasoftLogger;
import com.parasoft.xtest.logging.api.SystemHandlerFactory;

public final class JavascriptCoverageLogger {
    private static final String LOGGING_LEVEL_PROPERTY = "com.parasoft.xtest.logging.system.level";

    static {
        if (System.getProperty(LOGGING_LEVEL_PROPERTY) == null) {
            System.setProperty(LOGGING_LEVEL_PROPERTY, ParasoftLevel.INFO_LEVEL_LABEL);
        }

        SystemHandlerFactory factory = new SystemHandlerFactory();
        factory.isInitialized();
        ParasoftLogger.setCurrentFactory(factory);
    }

    public static ParasoftLogger getLogger() {
        return ParasoftLogger.getLogger();
    }
}
