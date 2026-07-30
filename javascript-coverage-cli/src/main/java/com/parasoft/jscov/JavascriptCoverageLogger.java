package com.parasoft.jscov;

import com.parasoft.xtest.logging.api.ParasoftLogger;

public class JavascriptCoverageLogger {
    private static final ParasoftLogger logger = ParasoftLogger.getLogger(JavascriptCoverage.class);

    public static ParasoftLogger getLogger() {
        return logger;
    }
}
