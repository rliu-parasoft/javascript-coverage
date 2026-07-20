package com.parasoft.jscov;

import com.parasoft.jscov.commandline.CommandLineParser;
import com.parasoft.jscov.logging.JavascriptCoverageLogger;
import com.parasoft.xtest.logging.api.ParasoftLogger;

import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;

public final class JavascriptCoverage {
    private static final ParasoftLogger logger = JavascriptCoverageLogger.getLogger();

    public static void main(String[] args) {
        try {
            // Get working directory
            Path workingDir = Path.of("").toAbsolutePath();
            Path jscAppDir = getJscAppDir(workingDir);
            String[] validatedArgs = CommandLineParser.parse(args, workingDir, jscAppDir).toArguments();

            // TODO: Invoke CoverageRunner with validatedArgs
            logger.info("Temporary log - Validated arguments: " + Arrays.toString(validatedArgs));
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
}
