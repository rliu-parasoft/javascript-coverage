package com.parasoft.jscov.logging;

import com.parasoft.xtest.logging.api.ParasoftLogger;
import com.parasoft.xtest.logging.api.SystemHandlerFactory;

public final class JavascriptCoverageLogger {

    static {
        SystemHandlerFactory factory = new SystemHandlerFactory();
        factory.isInitialized();
        ParasoftLogger.setCurrentFactory(factory);
    }

    public static ParasoftLogger getLogger() {
        return ParasoftLogger.getLogger();
    }
}
