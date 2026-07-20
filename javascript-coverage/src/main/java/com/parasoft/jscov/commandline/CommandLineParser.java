package com.parasoft.jscov.commandline;

import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.jscov.logging.JavascriptCoverageLogger;
import com.parasoft.xtest.common.nls.NLS;
import com.parasoft.xtest.logging.api.ParasoftLogger;

import java.nio.file.Path;
import java.util.*;

public final class CommandLineParser {
    static final String STATIC_ARGUMENT = "-static";
    static final String SETTINGS_ARGUMENT = "-settings";
    static final String REPORT_ARGUMENT = "-report";

    private static final ParasoftLogger logger = JavascriptCoverageLogger.getLogger();

    public static CommandLineInput parse(String[] args, Path workingDir, Path jscAppDir) {
        CommandLineInput.Command command = CommandLineInput.Command.COVERAGE;
        int argumentStartIndex = 0;
        if (args.length > 0 && !CommandLineValidator.isArgument(args[0])) {
            command = parseCommand(args[0]);
            argumentStartIndex = 1;
        }

        String[] rawArguments = Arrays.copyOfRange(args, argumentStartIndex, args.length);
        Map<String, List<String>> arguments = collectArguments(rawArguments);

        if (command == CommandLineInput.Command.COVERAGE) {
             return parseForCoverageCommand(arguments, workingDir, jscAppDir);
        } else if (command == CommandLineInput.Command.IMPACTED) {
            throw new UnsupportedOperationException("Need to implement");
        }

        throw new UnsupportedOperationException(NLS.bind(CommonMessages.UNSUPPORTED_COMMAND, command));
    }

    private static CommandLineInput parseForCoverageCommand(Map<String, List<String>> arguments, Path workingDir, Path jscAppDir) {
        normalizeOptionalArgument(arguments, SETTINGS_ARGUMENT, jscAppDir.resolve("settings.properties").toAbsolutePath());
        normalizeOptionalArgument(arguments, REPORT_ARGUMENT, workingDir.resolve("reports").toAbsolutePath());
        CommandLineValidator.validateCoverageArguments(arguments, workingDir);
        return new CommandLineInput(CommandLineInput.Command.COVERAGE, arguments);
    }

    private static CommandLineInput.Command parseCommand(String value) {
        if (CommandLineInput.Command.COVERAGE.value().equals(value)) {
            return CommandLineInput.Command.COVERAGE;
        }
        if (CommandLineInput.Command.IMPACTED.value().equals(value)) {
            return CommandLineInput.Command.IMPACTED;
        }
        throw new IllegalArgumentException(NLS.bind(CommonMessages.UNSUPPORTED_COMMAND, value));
    }

    private static Map<String, List<String>> collectArguments(String[] args) {
        Map<String, List<String>> arguments = new LinkedHashMap<>();
        for (int index = 0; index < args.length; index++) {
            String argument = args[index];
            if (!CommandLineValidator.isArgument(argument)) {
                if (arguments.containsKey(argument)) {
                    arguments.get(argument).add(null);
                } else {
                    List<String> values = new ArrayList<>();
                    values.add(null);
                    arguments.put(argument, values);
                }
                continue;
            }

            int valueIndex = index + 1;
            String value = null;
            if (valueIndex <= args.length - 1) {
                value = args[valueIndex];
            }
            if (CommandLineValidator.isArgument(value)) {
                value = null;
            } else {
                index++;
            }
            if (arguments.containsKey(argument)) {
                arguments.get(argument).add(value);
            } else {
                List<String> values = new ArrayList<>();
                values.add(value);
                arguments.put(argument, values);
            }
        }
        return arguments;
    }

    private static void normalizeOptionalArgument( Map<String, List<String>> arguments, String argumentName, Path defaultPath) {
        List<String> value = arguments.get(argumentName);
        if (value == null || value.isEmpty()) {
            logger.info(NLS.bind(CommonMessages.UNSPECIFIED_PARAMETER, argumentName, defaultPath.toAbsolutePath()));
            List<String> values = new ArrayList<>();
            values.add(defaultPath.toString());
            arguments.put(argumentName, values);
        }
    }
}
