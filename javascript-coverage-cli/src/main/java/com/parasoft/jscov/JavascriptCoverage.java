package com.parasoft.jscov;

import com.parasoft.xtest.coverage.all.*;
import com.parasoft.xtest.logging.api.ParasoftLogger;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class JavascriptCoverage {

    public static final String COVERAGE_ENGINE_PROPERTY = "parasoft.coverage.data.engine";
    public static final String PARASOFT_LOCAL_STORAGE_DIR = "parasoft.local.storage.dir";
    public static final String DOT_COVERAGE = ".coverage";

    private final String[] rawArgs;

    private JavascriptCoverage(String[] args) {
        rawArgs = args;

        String configuredEngine = System.getProperty(COVERAGE_ENGINE_PROPERTY);
        if ((configuredEngine == null) || configuredEngine.isBlank()) {
            System.setProperty(COVERAGE_ENGINE_PROPERTY, JavascriptCoverageDataEngine.class.getName());
        }

        configureLocalStorageDir();
    }

    public static void main(String[] args) {
        try {
            JavascriptCoverage coverage = new JavascriptCoverage(args);
            coverage.run();
        } catch (Throwable thr) {
            ParasoftLogger.getLogger().error(thr);
            System.exit(1);
        }
    }

    private void run() {
        String[] effectiveArgs = buildEffectiveArguments(rawArgs);
        CoverageRunner.main(effectiveArgs);
    }

    public static String[] buildEffectiveArguments(String[] args) {
        List<String> argList = new ArrayList<>(Arrays.asList(args));
        // TODO: Remove the default -ctp argument after the license module is integrated.
        argList.add("-ctp");
        return argList.toArray(new String[0]);
    }

    private void configureLocalStorageDir() {
        if (System.getProperty(PARASOFT_LOCAL_STORAGE_DIR) == null) {
            File storageDir = (new File(DOT_COVERAGE)).getAbsoluteFile();
            storageDir.mkdirs();
            String sDefStorageDir = storageDir.getAbsolutePath();
            System.setProperty(PARASOFT_LOCAL_STORAGE_DIR, sDefStorageDir);
        }
    }
}
