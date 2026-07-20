package com.parasoft.jscov.commandline;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

public class CommandLineParserTest {

    private Path createWorkingDir(Path directory) throws IOException {
        return Files.createDirectories(directory.resolve("workingDir"));
    }

    private Path createJscAppDir(Path directory) throws IOException {
        return Files.createDirectories(directory.resolve("jscAppDir"));
    }

    private Path createStaticFile(Path directory) throws Exception {
        return Files.writeString(directory.resolve("coverage.json"), "{}");
    }

    private Path createSettingsFile(Path directory) throws Exception {
        return Files.writeString(directory.resolve("settings.properties"), "");
    }

    private Path createReportFile(Path directory, String name) throws Exception {
        if (name == null) {
            return Files.createDirectories(directory.resolve("reports"));
        } else {
            return Files.createDirectories(directory.resolve(name));
        }
    }

    @Test
    void testParse_defaultsWhenNoCommandProvided(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);
        Path settingFile = createSettingsFile(jscAppDir);

        CommandLineInput input = CommandLineParser.parse(new String[]{"-static", staticFile.toString()}, workingDir, jscAppDir);

        assertEquals(CommandLineInput.Command.COVERAGE, input.getCommand());
        assertEquals(staticFile.toString(), input.getArguments().get("-static").get(0));
        assertEquals(settingFile.toString(), input.getArguments().get("-settings").get(0));
        assertEquals(workingDir.resolve("reports").toAbsolutePath().toString(), input.getArguments().get("-report").get(0));

        assertArrayEquals(new String[]{
                "-static", staticFile.toString(),
                "-settings", settingFile.toString(),
                "-report", workingDir.resolve("reports").toAbsolutePath().toString()
        }, input.toArguments());

    }

    @Test
    void testParse_resolvesRelativePaths(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);
        Path settingFile = createSettingsFile(workingDir);

        CommandLineInput input = CommandLineParser.parse(new String[]{"-static", "coverage.json", "-settings", "settings.properties", "-report", "custom_reports"}, workingDir, jscAppDir);

        assertEquals(staticFile.toString(), input.getArguments().get("-static").get(0));
        assertEquals(settingFile.toString(), input.getArguments().get("-settings").get(0));
        assertEquals(workingDir.resolve("custom_reports").toAbsolutePath().toString(), input.getArguments().get("-report").get(0));

    }

    @Test
    void testParse_preservesAbsolutePaths(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);
        Path settingFile = createSettingsFile(workingDir);
        Path reportDis = createReportFile(workingDir, "custom_reports");

        CommandLineInput input = CommandLineParser.parse(new String[]{"-static", staticFile.toString(), "-settings", settingFile.toString(), "-report", reportDis.toString()}, workingDir, jscAppDir);

        assertEquals(staticFile.toString(), input.getArguments().get("-static").get(0));
        assertEquals(settingFile.toString(), input.getArguments().get("-settings").get(0));
        assertEquals(reportDis.toAbsolutePath().toString(), input.getArguments().get("-report").get(0));
    }

    @Test
    void testParse_acceptsExplicitCoverageCommand(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);
        Path settingFile = createSettingsFile(jscAppDir);


        CommandLineInput input = CommandLineParser.parse(new String[]{"coverage", "-static", staticFile.toString()}, workingDir, jscAppDir);

        assertEquals(staticFile.toString(), input.getArguments().get("-static").get(0));
        assertEquals(settingFile.toString(), input.getArguments().get("-settings").get(0));
        assertEquals(workingDir.resolve("reports").toAbsolutePath().toString(), input.getArguments().get("-report").get(0));
    }

    @Test
    void testParse_defaultSettingsFileMissing(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);

        Path expectedDefaultSettingsFile = jscAppDir.resolve("settings.properties").toAbsolutePath();
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(new String[]{"-static", staticFile.toString()}, workingDir, jscAppDir));

        assertEquals(NLS.bind(CommonMessages.PROPERTIES_FILE_NOT_FOUND, expectedDefaultSettingsFile),
                exception.getMessage());
    }

    @Test
    void testParse_staticFileNotFound(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(new String[]{"coverage", "-static", "staticNotExisting"}, workingDir, jscAppDir));

        assertEquals(NLS.bind(CommonMessages.STATIC_COVERAGE_JSON_FILE_NOT_FOUND,
                workingDir.resolve("staticNotExisting").toAbsolutePath()), exception.getMessage());
    }

    @Test
    void testParse_settingsFileNotFound(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(
                        new String[]{"coverage", "-static", staticFile.toString(), "-settings", "settingsNotExisting"},
                        workingDir,
                        jscAppDir));

        assertEquals(NLS.bind(CommonMessages.PROPERTIES_FILE_NOT_FOUND,
                workingDir.resolve("settingsNotExisting").toAbsolutePath()), exception.getMessage());
    }

    @Test
    void testParse_settingsValueMissing(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(new String[]{
                        "coverage", "-static", staticFile.toString(), "-settings"
                }, workingDir, jscAppDir));

        assertEquals(NLS.bind(CommonMessages.UNEXPECTED_VALUE_FOR_PARAMETER, "-settings"), exception.getMessage());
    }

    @Test
    void testParse_reportValueMissing(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);
        createSettingsFile(jscAppDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(new String[]{
                        "coverage", "-static", staticFile.toString(), "-report"
                }, workingDir, jscAppDir));

        assertEquals(NLS.bind(CommonMessages.UNEXPECTED_VALUE_FOR_PARAMETER, "-report"), exception.getMessage());
    }

    @Test
    void testParse_missingRequiredParameter(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(new String[]{"coverage"}, workingDir, jscAppDir));

        assertEquals(NLS.bind(CommonMessages.MISSING_REQUIRED_PARAMETER, "-static"), exception.getMessage());
    }

    @Test
    void testParse_missingRequiredParameterValue(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(new String[]{"coverage", "-static"}, workingDir, jscAppDir));

        assertEquals(NLS.bind(CommonMessages.UNEXPECTED_VALUE_FOR_PARAMETER, "-static"), exception.getMessage());
    }

    @Test
    void testParse_rejectsDuplicateParameters(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);
        Path staticFile = createStaticFile(workingDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(
                        new String[]{"coverage", "-static", staticFile.toString(), "-static", staticFile.toString()},
                        workingDir,
                        jscAppDir));

        assertEquals(NLS.bind(CommonMessages.UNEXPECTED_VALUE_FOR_PARAMETER, "-static"), exception.getMessage());
    }

    @Test
    void testParse_unsupportedCommand(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(new String[]{"coverage1"}, workingDir, jscAppDir));
        assertEquals(NLS.bind(CommonMessages.UNSUPPORTED_COMMAND, "coverage1"), exception.getMessage());
    }

    @Test
    void testParse_reportsUnknownParameters(@TempDir Path tempDir) throws Exception {
        Path workingDir = createWorkingDir(tempDir);
        Path jscAppDir = createJscAppDir(tempDir);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> CommandLineParser.parse(new String[]{
                        "coverage", "coverage", "coverage", "-unknown1", "-unknown2", "value2"
                }, workingDir, jscAppDir));

        String unknownParameters = String.join("\n ", List.of(
                "coverage",
                "-unknown1",
                "-unknown2: value2"));
        assertEquals(NLS.bind(CommonMessages.UNKNOWN_PARAMETERS, unknownParameters), exception.getMessage());
    }
}
