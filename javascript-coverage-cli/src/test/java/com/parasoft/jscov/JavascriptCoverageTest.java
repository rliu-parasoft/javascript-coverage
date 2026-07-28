package com.parasoft.jscov;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

class JavascriptCoverageTest {

    @Test
    void buildEffectiveArguments_preservesXtestArgumentsAndAppendsCtp() {
        String[] rawArguments = {
                "coverage", "-app", "static-json", "-static", "base.xml",
                "-runtime", "runtime-data", "-settings", "settings.properties",
                "-report", "reports", "-include", "src/**", "-exclude", "test/**",
                "-property", "key=value", "-showdetails", "-publish", "-ctp",
                "-unknown", "value", "-include", "generated/**"
        };

        String[] expectedArguments = {
                "coverage", "-app", "static-json", "-static", "base.xml",
                "-runtime", "runtime-data", "-settings", "settings.properties",
                "-report", "reports", "-include", "src/**", "-exclude", "test/**",
                "-property", "key=value", "-showdetails", "-publish", "-ctp",
                "-unknown", "value", "-include", "generated/**", "-ctp"
        };

        assertArrayEquals(expectedArguments, JavascriptCoverage.buildEffectiveArguments(rawArguments));
    }

    @Test
    void buildEffectiveArguments_preservesTopLevelCommandsAndHelpArguments() {
        assertArrayEquals(new String[]{"impacted", "-app", "static-json", "-ctp"},
                JavascriptCoverage.buildEffectiveArguments(new String[]{"impacted", "-app", "static-json"}));
        assertArrayEquals(new String[]{"merge", "-coverage", "one.xml", "-coverage", "two.xml", "-ctp"},
                JavascriptCoverage.buildEffectiveArguments(new String[]{"merge", "-coverage", "one.xml", "-coverage", "two.xml"}));
        assertArrayEquals(new String[]{"help", "-ctp"},
                JavascriptCoverage.buildEffectiveArguments(new String[]{"help"}));
        assertArrayEquals(new String[]{"-help", "-ctp"},
                JavascriptCoverage.buildEffectiveArguments(new String[]{"-help"}));
    }

    @Test
    void buildEffectiveArguments_preservesFirstAppArgumentAndMissingValues() {
        String[] rawArguments = {"-app", "static-json", "-settings"};

        assertArrayEquals(new String[]{"-app", "static-json", "-settings", "-ctp"},
                JavascriptCoverage.buildEffectiveArguments(rawArguments));
    }

    @Test
    void buildEffectiveArguments_appendsCtpEvenWhenAlreadyPresent() {
        assertArrayEquals(new String[]{"coverage", "-ctp", "-ctp"},
                JavascriptCoverage.buildEffectiveArguments(new String[]{"coverage", "-ctp"}));
    }
}
