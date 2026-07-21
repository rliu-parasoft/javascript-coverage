package com.parasoft.jscov;

import com.parasoft.jscov.commandline.CommandLineParser;
import com.parasoft.jscov.logging.JavascriptCoverageLogger;
import com.parasoft.xtest.logging.api.ParasoftLogger;

import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;

import com.parasoft.xtest.coverage.all.CoverageRunner;

import java.util.ArrayList;
import java.util.List;


public final class JavascriptCoverage {
    private static final String COVERAGE_ENGINE_PROPERTY = "parasoft.coverage.data.engine";
    private static final ParasoftLogger logger = JavascriptCoverageLogger.getLogger();

    public static void main(String[] args) {
        try {
            String configuredEngine = System.getProperty(COVERAGE_ENGINE_PROPERTY);
            if ((configuredEngine == null) || configuredEngine.isBlank()) {
                System.setProperty(COVERAGE_ENGINE_PROPERTY, JavascriptCoverageDataEngine.class.getName());
            }

            // Get working directory
            Path workingDir = Path.of("").toAbsolutePath();
            Path jscAppDir = getJscAppDir(workingDir);
            String[] validatedArgs = CommandLineParser.parse(args, workingDir, jscAppDir).toArguments();

            String[] effectiveArgs = addAdditionalOption(validatedArgs);

            CoverageRunner.main(effectiveArgs);
        } catch (IllegalArgumentException exception) {
            // TODO: use console and logger in task JSC-49
            logger.debug(exception.getMessage(), exception);
            logger.error(exception.getMessage());
            System.exit(1);
        }
    }

    private static Path getJscAppDir(Path jscAppDirForDevelopmentMode) {
        try {
            Path jscAppcodeSourceLocation = Path.of(JavascriptCoverage.class.getProtectionDomain()
                    .getCodeSource().getLocation().toURI());
            if (Files.isDirectory(jscAppcodeSourceLocation)) {
                logger.info("Running in development mode. Set jscov app dir to " + jscAppDirForDevelopmentMode);
                return jscAppDirForDevelopmentMode;
            } else {
                // xxx/jscov.jar
                return jscAppcodeSourceLocation.getParent();
            }
        } catch (URISyntaxException exception) {
            throw new IllegalStateException("Unable to locate jscov.jar", exception);
        }
    }

    static String[] addAdditionalOption(String[] args) {
        List<String> argList = new ArrayList<>(Arrays.asList(args));

        argList.add("-ctp");

        return argList.toArray(new String[0]);
    }
}
