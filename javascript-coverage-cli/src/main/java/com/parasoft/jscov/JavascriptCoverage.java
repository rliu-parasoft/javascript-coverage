package com.parasoft.jscov;

import com.parasoft.jscov.commandline.CommandLineParser;
import com.parasoft.xtest.common.api.console.IConsole;
import com.parasoft.xtest.common.console.StdoutConsoleServiceFactory;
import com.parasoft.xtest.coverage.all.*;
import com.parasoft.jscov.commandline.CommandLineInput;
import com.parasoft.xtest.logging.api.ParasoftLogger;

import java.io.File;
import java.io.FileInputStream;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;

import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public final class JavascriptCoverage {

    public static final String COVERAGE_ENGINE_PROPERTY = "parasoft.coverage.data.engine";
    public static final String CONSOLE_VERBOSITY_LEVEL = "console.verbosity.level";
    public static final String PARASOFT_LOCAL_STORAGE_DIR = "parasoft.local.storage.dir";
    public static final String SETTINGS_PROPERTIES = "settings.properties";
    public static final String TECHSUPPORT_ENABLED = "techsupport.enabled";
    public static final String DOT_COVERAGE = ".coverage";

    private final String[] rawArgs;
    /**
     * Only the JSCov code should use this console instance.
     * The Xtest extension code should use the console provided by Xtest instead.<br/>
     * Only normal and high level can be output to the console.
     */
    public static IConsole jscConsole;
    // Working directory
    private final Path workingDir;
    // jsc.jar app directory
    private final Path jscAppDir;

    private JavascriptCoverage(String[] args) {
        rawArgs = args;

        String configuredEngine = System.getProperty(COVERAGE_ENGINE_PROPERTY);
        if ((configuredEngine == null) || configuredEngine.isBlank()) {
            System.setProperty(COVERAGE_ENGINE_PROPERTY, JavascriptCoverageDataEngine.class.getName());
        }

        configureLocalStorageDir();

        // Get working directory
        workingDir = Path.of("").toAbsolutePath();
        jscAppDir = getJscAppDir(workingDir);

        configureJscConsoleAndLogger();
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
        CommandLineInput commandLineInput = CommandLineParser.parse(rawArgs, workingDir, jscAppDir);
        String[] validatedArgs = commandLineInput.toArguments();
        rewriteArguments(commandLineInput, validatedArgs);
        String[] effectiveArgs = addAdditionalArguments(validatedArgs);

        CoverageRunner.main(effectiveArgs);
    }

    private static Path getJscAppDir(Path jscAppDirForDevelopmentMode) {
        try {
            Path jscAppcodeSourceLocation = Path.of(JavascriptCoverage.class.getProtectionDomain()
                    .getCodeSource().getLocation().toURI());
            if (Files.isDirectory(jscAppcodeSourceLocation)) {
                // Running in development mode. Set jscov app dir to ${jscAppDirForDevelopmentMode}
                return jscAppDirForDevelopmentMode;
            } else {
                // xxx/jscov.jar
                return jscAppcodeSourceLocation.getParent();
            }
        } catch (URISyntaxException exception) {
            throw new IllegalStateException("Unable to locate jscov.jar", exception);
        }
    }

    private static void rewriteArguments(CommandLineInput commandLineInput, String[] args) {
        if (commandLineInput.getCommand() == CommandLineInput.Command.COVERAGE) {
            int index = Arrays.asList(args).indexOf("-static");
            if (index >= 0) {
                args[index] = "-app";
            }
        }
    }

    private static String[] addAdditionalArguments(String[] args) {
        List<String> argList = new ArrayList<>(Arrays.asList(args));
        argList.add("-ctp");
        return argList.toArray(new String[0]);
    }

    private static Path getSettingsFile(String[] args, Path jscAppDir) {
        int index = Arrays.asList(args).indexOf(CommandLineParser.SETTINGS_ARGUMENT);
        if (index != -1 && index < args.length - 1) {
            String settingsFilePath = args[index + 1];
            return Path.of(settingsFilePath).toAbsolutePath();
        }
        return jscAppDir.resolve(SETTINGS_PROPERTIES).toAbsolutePath();
    }

    private void configureLocalStorageDir() {
        if (System.getProperty(PARASOFT_LOCAL_STORAGE_DIR) == null) {
            File storageDir = (new File(DOT_COVERAGE)).getAbsoluteFile();
            storageDir.mkdirs();
            String sDefStorageDir = storageDir.getAbsolutePath();
            System.setProperty(PARASOFT_LOCAL_STORAGE_DIR, sDefStorageDir);
        }
    }

    private void configureJscConsoleAndLogger() {
        Path settingsFile = getSettingsFile(rawArgs, jscAppDir);
        Properties properties = new Properties();
        if (Files.isRegularFile(settingsFile)) {
            try (FileInputStream fis = new FileInputStream(settingsFile.toFile())) {
                properties.load(fis);
            } catch (Throwable thr) {
                // Do nothing
            }
        }

        String consoleVerbosityLevel = properties.getProperty(CONSOLE_VERBOSITY_LEVEL);
        CoverageContextWithConsole context = new CoverageContextWithConsole();
        if (consoleVerbosityLevel != null && Arrays.asList("normal", "high", "low").contains(consoleVerbosityLevel)) {
            context.getPreferences().setProperty(CONSOLE_VERBOSITY_LEVEL, consoleVerbosityLevel);
        } else {
            context.getPreferences().setProperty(CONSOLE_VERBOSITY_LEVEL, "normal");
        }
        StdoutConsoleServiceFactory consoleServiceFactory = new StdoutConsoleServiceFactory();
        IConsole console = consoleServiceFactory.getService(context).getConsole(null);
        context.setConsole(console);
        jscConsole = console;

        String techSupportEnabled = properties.getProperty(TECHSUPPORT_ENABLED);
        ParasoftLogger.configure(Boolean.parseBoolean(techSupportEnabled));
    }
}
