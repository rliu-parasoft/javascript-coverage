package com.parasoft.jscov;

import com.parasoft.xtest.coverage.all.CoverageRunner;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mockStatic;

class JavascriptCoverageTest {

    @Test
    void main_providesEffectiveArgumentsToCoverageRunner() {
        String previousEngine = System.getProperty(JavascriptCoverage.COVERAGE_ENGINE_PROPERTY);
        String previousStorage = System.getProperty(JavascriptCoverage.PARASOFT_LOCAL_STORAGE_DIR);
        try {
            System.setProperty(JavascriptCoverage.COVERAGE_ENGINE_PROPERTY, "custom.Engine");
            System.setProperty(JavascriptCoverage.PARASOFT_LOCAL_STORAGE_DIR, "custom-storage");

            try (MockedStatic<CoverageRunner> runner = mockStatic(CoverageRunner.class)) {
                JavascriptCoverage.main(new String[]{"-app", "static-json"});

                runner.verify(() -> CoverageRunner.main(new String[]{"-app", "static-json", "-ctp"}));
                assertEquals("custom.Engine",
                        System.getProperty(JavascriptCoverage.COVERAGE_ENGINE_PROPERTY));
                assertEquals("custom-storage",
                        System.getProperty(JavascriptCoverage.PARASOFT_LOCAL_STORAGE_DIR));
            }
        } finally {
            restoreProperty(JavascriptCoverage.COVERAGE_ENGINE_PROPERTY, previousEngine);
            restoreProperty(JavascriptCoverage.PARASOFT_LOCAL_STORAGE_DIR, previousStorage);
        }
    }

    @Test
    void main_setsDefaultEngineAndLocalStorageWhenPropertiesAreUnset() {
        String previousEngine = System.getProperty(JavascriptCoverage.COVERAGE_ENGINE_PROPERTY);
        String previousStorage = System.getProperty(JavascriptCoverage.PARASOFT_LOCAL_STORAGE_DIR);
        try {
            System.clearProperty(JavascriptCoverage.COVERAGE_ENGINE_PROPERTY);
            System.clearProperty(JavascriptCoverage.PARASOFT_LOCAL_STORAGE_DIR);

            try (MockedStatic<CoverageRunner> runner = mockStatic(CoverageRunner.class)) {
                JavascriptCoverage.main(new String[]{"-app", "static-json"});

                assertEquals(JavascriptCoverageDataEngine.class.getName(),
                        System.getProperty(JavascriptCoverage.COVERAGE_ENGINE_PROPERTY));
                assertEquals(new java.io.File(JavascriptCoverage.DOT_COVERAGE).getAbsolutePath(),
                        System.getProperty(JavascriptCoverage.PARASOFT_LOCAL_STORAGE_DIR));
            }
        } finally {
            restoreProperty(JavascriptCoverage.COVERAGE_ENGINE_PROPERTY, previousEngine);
            restoreProperty(JavascriptCoverage.PARASOFT_LOCAL_STORAGE_DIR, previousStorage);
        }
    }

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

    private static void restoreProperty(String name, String value) {
        if (value == null) {
            System.clearProperty(name);
        } else {
            System.setProperty(name, value);
        }
    }
}
