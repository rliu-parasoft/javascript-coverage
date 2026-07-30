package com.parasoft.jscov.coverage;

import com.parasoft.jscov.JavascriptCoverageLogger;
import com.parasoft.jscov.coverage.istanbul.IstanbulFunctionLineMapper;
import com.parasoft.jscov.coverage.istanbul.IstanbulJsonCoverageReader;
import com.parasoft.jscov.coverage.istanbul.dto.FunctionLineCoverageDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.IstanbulProjectDto;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.api.MessageSeverity;
import com.parasoft.xtest.common.api.console.IConsole;
import com.parasoft.xtest.common.nls.NLS;
import com.parasoft.xtest.coverage.all.api.ICoverageContext;
import com.parasoft.xtest.logging.api.ParasoftLogger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.MockedStatic;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Properties;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class StaticCoverageParserTest {

    private ICoverageContext context;
    private IConsole console;
    private ParasoftLogger logger;

    @BeforeEach
    void setUp() {
        context = mock(ICoverageContext.class);
        console = mock(IConsole.class);
        when(context.getConsole()).thenReturn(console);
        logger = mock(ParasoftLogger.class);
    }

    @Test
    void parse_returnsFileCoverageForEachJson(@TempDir Path appDir) throws IOException {
        Path jsonA = Files.createFile(appDir.resolve("a.json"));
        Path jsonB = Files.createFile(appDir.resolve("b.json"));

        IstanbulSourceFileCoverageDto dtoA = sourceDto("/proj/root/src/a.js", project("demo", "/proj/root"));
        IstanbulSourceFileCoverageDto dtoB = sourceDto("/proj/root/src/b.js", project("demo", "/proj/root"));

        FunctionLineCoverageDto fnA = new FunctionLineCoverageDto("fn:a:1", "alpha",
                new LinkedHashSet<>(List.of(10, 11)));
        FunctionLineCoverageDto fnB = new FunctionLineCoverageDto("fn:b:1", "beta",
                new LinkedHashSet<>(List.of(20)));

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class);
             MockedStatic<JavascriptCoverageLogger> loggerStatic = mockStatic(JavascriptCoverageLogger.class)) {
            loggerStatic.when(JavascriptCoverageLogger::getLogger).thenReturn(logger);
            reader.when(() -> IstanbulJsonCoverageReader.read(jsonA)).thenReturn(dtoA);
            reader.when(() -> IstanbulJsonCoverageReader.read(jsonB)).thenReturn(dtoB);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dtoA)).thenReturn(List.of(fnA));
            mapper.when(() -> IstanbulFunctionLineMapper.map(dtoB)).thenReturn(List.of(fnB));

            List<FileCoverage> result = StaticCoverageParser.parse(appDir, context, null);

            assertEquals(2, result.size());

            FileCoverage first = result.get(0);
            assertEquals("a.js", first.getFileLocation().getName());
            assertEquals(first.getFileLocation().toURI().toString(), first.getReferenceId());
            assertEquals(1, first.getStaticItems().size());

            CoverableItemNode fileNode = first.getStaticItems().get(0);
            assertEquals("a", fileNode.getDisplayName());
            assertEquals("a.js", fileNode.getItemId());
            assertTrue(fileNode.getCoverableLines().isEmpty());
            assertEquals(1, fileNode.getChildren().size());

            CoverableItemNode fnNode = fileNode.getChildren().get(0);
            assertEquals("alpha", fnNode.getDisplayName());
            assertEquals("fn:a:1", fnNode.getItemId());
            assertEquals(List.of(10, 11), fnNode.getCoverableLines());

            Properties propsA = first.getLocationProperties();
            assertEquals("demo", propsA.getProperty("projId"));
            assertEquals("demo", propsA.getProperty("project"));
            assertEquals("/demo", propsA.getProperty("projPath"));
            assertEquals("src/a.js", propsA.getProperty("resProjPath"));

            verify(logger).debug(eq(NLS.getFormatted(CommonMessages.PARSING_ISTANBUL_JSON_FILE, jsonA)));
            verify(logger).debug(eq(NLS.getFormatted(CommonMessages.PARSING_ISTANBUL_JSON_FILE, jsonB)));
        }
    }

    @Test
    void parse_emptyDirectory_throwsAndReportsToConsole(@TempDir Path emptyDir) {
        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class);
             MockedStatic<JavascriptCoverageLogger> loggerStatic = mockStatic(JavascriptCoverageLogger.class)) {
            loggerStatic.when(JavascriptCoverageLogger::getLogger).thenReturn(logger);

            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                    () -> StaticCoverageParser.parse(emptyDir, context, null));

            String expectedMessage = NLS.getFormatted(CommonMessages.NO_ISTANBUL_JSON_FILES_FOUND, emptyDir);
            assertEquals(expectedMessage, ex.getMessage());
            verify(console).writeln(eq(expectedMessage), eq(MessageSeverity.HIGH));
            reader.verifyNoInteractions();
            mapper.verifyNoInteractions();
        }
    }

    @Test
    void parse_skipsDuplicateFileNamesAndLogsLowSeverity(@TempDir Path appDir) throws IOException {
        Path subA = Files.createDirectories(appDir.resolve("a"));
        Path subB = Files.createDirectories(appDir.resolve("b"));
        Path first = Files.createFile(subA.resolve("dup.json"));
        Path duplicate = Files.createFile(subB.resolve("dup.json"));

        // Only whichever comes first (sorted) is parsed; the other is skipped.
        Path expectedParsed = first.compareTo(duplicate) < 0 ? first : duplicate;
        Path expectedSkipped = first.compareTo(duplicate) < 0 ? duplicate : first;

        IstanbulSourceFileCoverageDto dto = sourceDto("/proj/root/dup.js", project("demo", "/proj/root"));

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class);
             MockedStatic<JavascriptCoverageLogger> loggerStatic = mockStatic(JavascriptCoverageLogger.class)) {
            loggerStatic.when(JavascriptCoverageLogger::getLogger).thenReturn(logger);
            reader.when(() -> IstanbulJsonCoverageReader.read(any(Path.class))).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(any())).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(appDir, context, null);

            assertEquals(1, result.size());
            reader.verify(() -> IstanbulJsonCoverageReader.read(expectedParsed), times(1));

            String expectedMessage = NLS.getFormatted(CommonMessages.SKIPPING_DUPLICATE_JSON_FILES,
                    "dup.json", List.of(expectedSkipped));
            verify(logger).debug(eq(expectedMessage));
        }
    }

    @Test
    void parse_continuesWhenReaderThrows(@TempDir Path appDir) throws IOException {
        Path bad = Files.createFile(appDir.resolve("bad.json"));
        Path good = Files.createFile(appDir.resolve("good.json"));

        IstanbulSourceFileCoverageDto dto = sourceDto("/proj/root/good.js", project("demo", "/proj/root"));
        IOException ioException = new IOException("boom");

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class);
             MockedStatic<JavascriptCoverageLogger> loggerStatic = mockStatic(JavascriptCoverageLogger.class)) {
            loggerStatic.when(JavascriptCoverageLogger::getLogger).thenReturn(logger);
            reader.when(() -> IstanbulJsonCoverageReader.read(bad)).thenThrow(ioException);
            reader.when(() -> IstanbulJsonCoverageReader.read(good)).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dto)).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(appDir, context, null);

            assertEquals(1, result.size());
            assertEquals("good.js", result.get(0).getFileLocation().getName());

            String expectedMessage = NLS.getFormatted(CommonMessages.FAILED_TO_PARSE_ISTANBUL_JSON, bad);
            verify(console).writeln(eq(expectedMessage), eq(MessageSeverity.HIGH));
            verify(logger).error(eq(expectedMessage), eq(ioException));

            mapper.verify(() -> IstanbulFunctionLineMapper.map(dto), times(1));
            mapper.verify(() -> IstanbulFunctionLineMapper.map(any()), times(1));
        }
    }

    @Test
    void parse_whenAllJsonFilesFail_throwsAndReportsNoValidFiles(@TempDir Path appDir) throws IOException {
        Path bad = Files.createFile(appDir.resolve("bad.json"));
        IOException ioException = new IOException("boom");

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            reader.when(() -> IstanbulJsonCoverageReader.read(bad)).thenThrow(ioException);

            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                    () -> StaticCoverageParser.parse(appDir, context, null));

            String expectedMessage = NLS.getFormatted(
                    CommonMessages.NO_VALID_ISTANBUL_JSON_FILES_FOUND_IN_DIRECTORY,
                    appDir.toAbsolutePath().toString());
            assertEquals(expectedMessage, ex.getMessage());
            verify(console).writeln(eq(expectedMessage), eq(MessageSeverity.HIGH));
            mapper.verifyNoInteractions();
        }
    }

    @Test
    void parse_missingProject_setsUnknownAttributes(@TempDir Path appDir) throws IOException {
        Path json = Files.createFile(appDir.resolve("noproj.json"));

        IstanbulSourceFileCoverageDto dto = sourceDto("some\\weird\\path\\noproj.js", null);

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class);
             MockedStatic<JavascriptCoverageLogger> loggerStatic = mockStatic(JavascriptCoverageLogger.class)) {
            loggerStatic.when(JavascriptCoverageLogger::getLogger).thenReturn(logger);
            reader.when(() -> IstanbulJsonCoverageReader.read(json)).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dto)).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(appDir, context, null);

            assertEquals(1, result.size());
            Properties props = result.get(0).getLocationProperties();
            assertEquals("unknown", props.getProperty("projId"));
            assertEquals("unknown", props.getProperty("project"));
            assertEquals("/unknown", props.getProperty("projPath"));
            // With no project root, resProjPath falls back to the raw source path with forward slashes.
            assertEquals("some/weird/path/noproj.js", props.getProperty("resProjPath"));
        }
    }

    @Test
    void parse_sourceOutsideProjectRoot_usesRawPathForResProjPath(@TempDir Path appDir) throws IOException {
        Path json = Files.createFile(appDir.resolve("outside.json"));

        // Use OS-appropriate absolute paths so Path.toAbsolutePath() is stable.
        Path projectRoot = appDir.resolve("proj-root");
        Path sourceOutside = appDir.resolve("other").resolve("outside.js");
        IstanbulSourceFileCoverageDto dto = sourceDto(sourceOutside.toString(),
                project("demo", projectRoot.toString()));

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            reader.when(() -> IstanbulJsonCoverageReader.read(json)).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dto)).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(appDir, context, null);

            String expected = sourceOutside.toString().replace('\\', '/');
            assertEquals(expected, result.get(0).getLocationProperties().getProperty("resProjPath"));
        }
    }

    private static IstanbulSourceFileCoverageDto sourceDto(String path, IstanbulProjectDto project) {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(path);
        dto.setProject(project);
        return dto;
    }

    private static IstanbulProjectDto project(String name, String root) {
        IstanbulProjectDto p = new IstanbulProjectDto();
        p.setName(name);
        p.setRoot(root);
        return p;
    }
}


