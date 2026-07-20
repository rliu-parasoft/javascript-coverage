package com.parasoft.jscov.commandline;

import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

class CommandLineValidator {

    static boolean isArgument(String value) {
        return value != null && value.startsWith("-");
    }

    static void validateCoverageArguments(Map<String, List<String>> args, Path workingDir) {
        validateCoverageArgumentNames(args);
        validateStaticArgument(args, workingDir);
        validateSettingsArgument(args, workingDir);
        validateReportArgument(args, workingDir);
    }

    private static void validateCoverageArgumentNames(Map<String, List<String>> args) {
        if (args == null || args.isEmpty()) {
            return;
        }
        List<String> unknownParameters = new ArrayList<>();
        for (String key : args.keySet()) {
            if (!(CommandLineParser.STATIC_ARGUMENT.equals(key)
                    || CommandLineParser.SETTINGS_ARGUMENT.equals(key)
                    || CommandLineParser.REPORT_ARGUMENT.equals(key))) {
                List<String> values = args.get(key);
                if (values == null || values.isEmpty()) {
                    unknownParameters.add(key);
                } else {
                    List<String> result = values.stream()
                            .filter(Objects::nonNull)
                            .toList();
                    if (result.isEmpty()) {
                        unknownParameters.add(key);
                    } else {
                        unknownParameters.add(key + ": " + String.join(", ", result));
                    }
                }

            }
        }
        if(!unknownParameters.isEmpty()) {
            throw new IllegalArgumentException(NLS.bind(CommonMessages.UNKNOWN_PARAMETERS, String.join("\n ", unknownParameters)));
        }
    }

    private static void validateStaticArgument(Map<String, List<String>> args, Path workingDir) {
        requireNotNoneArgumentAndOnlyWithOneValue(args, CommandLineParser.STATIC_ARGUMENT);

        Path staticCoverageJsonFile = resolveAgainstWorkingDir(args.get(CommandLineParser.STATIC_ARGUMENT).get(0), workingDir);
        if (!Files.isRegularFile(staticCoverageJsonFile)) {
            throw new IllegalArgumentException(NLS.bind(CommonMessages.STATIC_COVERAGE_JSON_FILE_NOT_FOUND, staticCoverageJsonFile));
        }

        args.get(CommandLineParser.STATIC_ARGUMENT).set(0, staticCoverageJsonFile.toAbsolutePath().toString());
    }

    private static void validateSettingsArgument(Map<String, List<String>> args, Path workingDir) {
        requireNotNoneArgumentAndOnlyWithOneValue(args, CommandLineParser.SETTINGS_ARGUMENT);

        Path settingsFile = resolveAgainstWorkingDir(args.get(CommandLineParser.SETTINGS_ARGUMENT).get(0), workingDir);
        if (!Files.isRegularFile(settingsFile)) {
            throw new IllegalArgumentException(NLS.bind(CommonMessages.PROPERTIES_FILE_NOT_FOUND, settingsFile));
        }
        args.get(CommandLineParser.SETTINGS_ARGUMENT).set(0, settingsFile.toAbsolutePath().toString());
    }

    private static void validateReportArgument(Map<String, List<String>> args, Path workingDir) {
        requireNotNoneArgumentAndOnlyWithOneValue(args, CommandLineParser.REPORT_ARGUMENT);
        Path reportDir = resolveAgainstWorkingDir(args.get(CommandLineParser.REPORT_ARGUMENT).get(0), workingDir);
        args.get(CommandLineParser.REPORT_ARGUMENT).set(0, reportDir.toAbsolutePath().toString());
    }

    private static void requireNotNoneArgumentAndOnlyWithOneValue(Map<String, List<String>> args, String key) {
        requireNotNoneArgument(args, key);

        List<String> values = args.get(key);
        if (values.size() > 1 || values.get(0) == null) {
            throw new IllegalArgumentException(NLS.bind(CommonMessages.UNEXPECTED_VALUE_FOR_PARAMETER, key));
        }
    }

    private static void requireNotNoneArgument(Map<String, List<String>> args, String key) {
        if (args == null || args.isEmpty()) {
            throw new IllegalArgumentException(NLS.bind(CommonMessages.MISSING_REQUIRED_PARAMETER, key));
        }

        if (!args.containsKey(key)) {
            throw new IllegalArgumentException(NLS.bind(CommonMessages.MISSING_REQUIRED_PARAMETER, key));
        }

        List<String> values = args.get(key);
        if (values == null || values.isEmpty()) {
            throw new IllegalArgumentException(NLS.bind(CommonMessages.MISSING_VALUE_FOR_PARAMETER, key));
        }
    }

    public static Path resolveAgainstWorkingDir(String value, Path workingDir) {
        Path path = Path.of(value);
        return path.isAbsolute() ? path : workingDir.resolve(path);
    }
}
