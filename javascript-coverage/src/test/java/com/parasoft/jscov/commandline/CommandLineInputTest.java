package com.parasoft.jscov.commandline;

import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static com.parasoft.jscov.commandline.CommandLineInput.Command.COVERAGE;
import static com.parasoft.jscov.commandline.CommandLineParser.STATIC_ARGUMENT;
import static org.junit.jupiter.api.Assertions.*;

class CommandLineInputTest {

    @Test
    void testToArguments_emptyValues() {
        Map<String, List<String>> arguments = new HashMap<>();
        arguments.put(STATIC_ARGUMENT, Collections.emptyList());
        CommandLineInput commandLineInput = new CommandLineInput(COVERAGE, arguments);

        String[] argumentsArray = commandLineInput.toArguments();

        assertEquals(2, argumentsArray.length);
        assertArrayEquals(new String[] {STATIC_ARGUMENT, ""}, argumentsArray);
    }

    @Test
    void testToArguments_noValues() {
        Map<String, List<String>> arguments = new HashMap<>();
        arguments.put(STATIC_ARGUMENT, null);
        CommandLineInput commandLineInput = new CommandLineInput(COVERAGE, arguments);

        String[] argumentsArray = commandLineInput.toArguments();

        assertEquals(2, argumentsArray.length);
        assertArrayEquals(new String[] {STATIC_ARGUMENT, ""}, argumentsArray);
    }
}