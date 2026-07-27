package com.parasoft.jscov.commandline;

import java.util.*;

public class CommandLineInput {

    private final Command command;
    private final Map<String, List<String>> arguments;

    public CommandLineInput(Command command, Map<String, List<String>> arguments) {
        this.command = command;
        this.arguments = Objects.requireNonNullElseGet(arguments, HashMap::new);
    }

    public String[] toArguments() {
        List<String> result = new ArrayList<>();
        arguments.forEach((name, value) -> {
            if (value == null || value.isEmpty()) {
                result.add(name);
                result.add("");
            } else {
                value.forEach(v -> {
                    result.add(name);
                    result.add(v);
                });
            }
        });
        return result.toArray(String[]::new);
    }

    public Command getCommand() {
        return command;
    }

    public Map<String, List<String>> getArguments() {
        return arguments;
    }

    @Override
    public String toString() {
        return "CommandLineInput{" +
                "command=" + command.value +
                ", arguments=" + arguments +
                '}';
    }

    public enum Command {
        COVERAGE("coverage"),
        IMPACTED("impacted");

        private final String value;

        Command(String value) {
            this.value = value;
        }

        public String value() {
            return value;
        }
    }
}
