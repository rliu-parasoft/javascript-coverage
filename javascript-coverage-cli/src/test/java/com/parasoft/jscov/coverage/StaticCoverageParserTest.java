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
import com.parasoft.xtest.logging.api.ILoggerHandler;
import com.parasoft.xtest.logging.api.ParasoftLevel;
import com.parasoft.xtest.logging.api.ParasoftLogger;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.MockedStatic;

import java.io.IOException;
import java.lang.reflect.Field;
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
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class StaticCoverageParserTest {

    private ICoverageContext context;
    private IConsole console;
    private ILoggerHandler loggerHandler;
    private ParasoftLogger javascriptCoverageLogger;
    private Object originalLoggerHandler;

    @BeforeEach
    void setUp() throws ReflectiveOperationException {
        context = mock(ICoverageContext.class);
        console = mock(IConsole.class);
        when(context.getConsole()).thenReturn(console);
        loggerHandler = mock(ILoggerHandler.class);
        javascriptCoverageLogger = JavascriptCoverageLogger.getLogger();
        Field handlerField = loggerHandlerField();
        originalLoggerHandler = handlerField.get(javascriptCoverageLogger);
        handlerField.set(javascriptCoverageLogger, loggerHandler);
    }

    @AfterEach
    void restoreLoggerHandler() throws ReflectiveOperationException {
        if (javascriptCoverageLogger != null) {
            loggerHandlerField().set(javascriptCoverageLogger, originalLoggerHandler);
        }
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
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
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

        }
    }

    @Test
    void parse_whenInputIsSessionDirectory_doesNotParseVersionManifestAsCoverage(@TempDir Path sessionDir)
            throws IOException {
        Path manifest = Files.createFile(sessionDir.resolve("version.json"));
        Path coverage = Files.createFile(sessionDir.resolve("coverage.json"));
        IstanbulSourceFileCoverageDto dto = sourceDto("/proj/root/source.js", project("demo", "/proj/root"));

        try (MockedStatic<StaticCoverageVersionManifestReader> manifestReader = mockStatic(StaticCoverageVersionManifestReader.class);
             MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            manifestReader.when(() -> StaticCoverageVersionManifestReader.read(sessionDir))
                    .thenReturn(StaticCoverageSchemaVersion.V1_0);
            reader.when(() -> IstanbulJsonCoverageReader.read(coverage)).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dto)).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(sessionDir, context, null);

            assertEquals(1, result.size());
            reader.verify(() -> IstanbulJsonCoverageReader.read(coverage), times(1));
            reader.verify(() -> IstanbulJsonCoverageReader.read(manifest), never());
        }
    }

    @Test
    void parse_whenManifestIsMalformed_skipsSessionAndDoesNotWriteToConsole(@TempDir Path coverageRoot)
            throws IOException {
        Path malformedSession = Files.createDirectories(coverageRoot.resolve("a-malformed"));
        Path validSession = Files.createDirectories(coverageRoot.resolve("b-valid"));
        Path malformedCoverage = Files.createFile(malformedSession.resolve("bad.json"));
        Path validCoverage = Files.createFile(validSession.resolve("good.json"));
        Files.writeString(malformedSession.resolve("version.json"), "{ invalid json");
        writeManifest(validSession, "1.0");
        IOException manifestException = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(malformedSession));
        IstanbulSourceFileCoverageDto dto = sourceDto("/proj/root/good.js", project("demo", "/proj/root"));

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            reader.when(() -> IstanbulJsonCoverageReader.read(validCoverage)).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dto)).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(coverageRoot, context, null);

            assertEquals(1, result.size());
            reader.verify(() -> IstanbulJsonCoverageReader.read(malformedCoverage), never());
            reader.verify(() -> IstanbulJsonCoverageReader.read(validCoverage), times(1));
            String sessionMessage = NLS.getFormatted(CommonMessages.SKIPPED_STATIC_COVERAGE_SESSION,
                    malformedSession, manifestException.getMessage());
            verify(loggerHandler).log(anyString(), eq(ParasoftLevel.DEBUG), eq((Object) sessionMessage), isNull());
            verify(console, never()).writeln(anyString(), eq(MessageSeverity.HIGH));
        }
    }

    @Test
    void parse_whenSchemaVersionIsUnsupported_skipsSessionAndDoesNotWriteToConsole(@TempDir Path coverageRoot)
            throws IOException {
        Path unsupportedSession = Files.createDirectories(coverageRoot.resolve("a-unsupported"));
        Path validSession = Files.createDirectories(coverageRoot.resolve("b-valid"));
        Path unsupportedCoverage = Files.createFile(unsupportedSession.resolve("bad.json"));
        Path validCoverage = Files.createFile(validSession.resolve("good.json"));
        writeManifest(unsupportedSession, "1.0.1");
        writeManifest(validSession, "1.0");
        IOException manifestException = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(unsupportedSession));
        IstanbulSourceFileCoverageDto dto = sourceDto("/proj/root/good.js", project("demo", "/proj/root"));

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            reader.when(() -> IstanbulJsonCoverageReader.read(validCoverage)).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dto)).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(coverageRoot, context, null);

            assertEquals(1, result.size());
            reader.verify(() -> IstanbulJsonCoverageReader.read(unsupportedCoverage), never());
            reader.verify(() -> IstanbulJsonCoverageReader.read(validCoverage), times(1));
            String sessionMessage = NLS.getFormatted(CommonMessages.SKIPPED_STATIC_COVERAGE_SESSION,
                    unsupportedSession, manifestException.getMessage());
            verify(loggerHandler).log(anyString(), eq(ParasoftLevel.DEBUG), eq((Object) sessionMessage), isNull());
            verify(console, never()).writeln(anyString(), eq(MessageSeverity.HIGH));
        }
    }

    @Test
    void parse_whenAllSessionsAreSkipped_throwsNoJsonFilesErrorWithoutPrintingSkipDetails(@TempDir Path coverageRoot)
            throws IOException {
        Path unsupportedSession = Files.createDirectories(coverageRoot.resolve("a-unsupported"));
        Files.createFile(unsupportedSession.resolve("bad.json"));
        writeManifest(unsupportedSession, "1.0.1");
        IOException manifestException = assertThrows(IOException.class,
                () -> StaticCoverageVersionManifestReader.read(unsupportedSession));

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> StaticCoverageParser.parse(coverageRoot, context, null));

        assertEquals(NLS.getFormatted(CommonMessages.NO_STATIC_COVERAGE_JSON_FILES_FOUND,
                coverageRoot.toAbsolutePath().toString()), exception.getMessage());
        String sessionMessage = NLS.getFormatted(CommonMessages.SKIPPED_STATIC_COVERAGE_SESSION,
                unsupportedSession, manifestException.getMessage());
        verify(console).writeln(eq(exception.getMessage()), eq(MessageSeverity.HIGH));
        verify(console, never()).writeln(eq(sessionMessage), eq(MessageSeverity.HIGH));
    }

    @Test
    void parse_whenDirectoryContainsOnlyNonJsonFiles_throwsAndReportsToConsole(@TempDir Path appDir) throws IOException {
        Files.createFile(appDir.resolve("readme.txt"));

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> StaticCoverageParser.parse(appDir, context, null));

        assertEquals(NLS.getFormatted(CommonMessages.NO_STATIC_COVERAGE_JSON_FILES_FOUND,
                appDir.toAbsolutePath().toString()), exception.getMessage());
        verify(console).writeln(eq(exception.getMessage()), eq(MessageSeverity.HIGH));
    }

    @Test
    void parse_skipsDuplicateFileNamesAndLogsDebugMessage(@TempDir Path appDir) throws IOException {
        Path staticCoverageDir = Files.createDirectories(appDir.resolve(".parasoft/static-coverage"));
        Path subA = Files.createDirectories(staticCoverageDir.resolve("a"));
        Path subB = Files.createDirectories(staticCoverageDir.resolve("b"));
        Path first = Files.createFile(subA.resolve("dup.json"));
        Path duplicate = Files.createFile(subB.resolve("dup.json"));

        // Only whichever comes first (sorted) is parsed; the other is skipped.
        Path expectedParsed = first.compareTo(duplicate) < 0 ? first : duplicate;
        Path expectedSkipped = first.compareTo(duplicate) < 0 ? duplicate : first;

        IstanbulSourceFileCoverageDto dto = sourceDto("/proj/root/dup.js", project("demo", "/proj/root"));

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            reader.when(() -> IstanbulJsonCoverageReader.read(any(Path.class))).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(any())).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(staticCoverageDir, context, null);

            assertEquals(1, result.size());
            reader.verify(() -> IstanbulJsonCoverageReader.read(expectedParsed), times(1));
            reader.verify(() -> IstanbulJsonCoverageReader.read(expectedSkipped), never());

            String expectedSkippedLogPath = ".parasoft/static-coverage/" + expectedSkipped.getParent().getFileName()
                    + "/" + expectedSkipped.getFileName();
            String expectedMessage = NLS.getFormatted(CommonMessages.SKIPPED_DUPLICATE_JSON_FILES,
                    "dup.json", expectedSkippedLogPath);
            verify(loggerHandler).log(anyString(), eq(ParasoftLevel.DEBUG), eq((Object) expectedMessage), isNull());
        }
    }

    @Test
    void parse_whenCoverageJsonCannotBeRead_continuesWithRemainingFiles(@TempDir Path appDir) throws IOException {
        Path bad = Files.createFile(appDir.resolve("bad.json"));
        Path good = Files.createFile(appDir.resolve("good.json"));

        IstanbulSourceFileCoverageDto dto = sourceDto("/proj/root/good.js", project("demo", "/proj/root"));
        IOException ioException = new IOException("boom");

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            reader.when(() -> IstanbulJsonCoverageReader.read(bad)).thenThrow(ioException);
            reader.when(() -> IstanbulJsonCoverageReader.read(good)).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dto)).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(appDir, context, null);

            assertEquals(1, result.size());
            assertEquals("good.js", result.get(0).getFileLocation().getName());

            String expectedMessage = NLS.getFormatted(CommonMessages.FAILED_TO_PARSE_STATIC_COVERAGE_JSON, bad);
            verify(console).writeln(eq(expectedMessage), eq(MessageSeverity.HIGH));
            verify(loggerHandler).log(anyString(), eq(ParasoftLevel.ERROR), eq((Object) expectedMessage), same(ioException));
            mapper.verify(() -> IstanbulFunctionLineMapper.map(dto), times(1));
            mapper.verify(() -> IstanbulFunctionLineMapper.map(any()), times(1));
        }
    }

    @Test
    void parse_whenNoCoverageJsonCanBeParsed_throwsAndReportsNoValidFiles(@TempDir Path appDir) throws IOException {
        Path bad = Files.createFile(appDir.resolve("bad.json"));
        IOException ioException = new IOException("boom");

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            reader.when(() -> IstanbulJsonCoverageReader.read(bad)).thenThrow(ioException);

            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                    () -> StaticCoverageParser.parse(appDir, context, null));

            String expectedMessage = NLS.getFormatted(
                    CommonMessages.NO_VALID_STATIC_COVERAGE_JSON_FILES_FOUND_IN_DIRECTORY,
                    appDir.toAbsolutePath().toString());
            assertEquals(expectedMessage, ex.getMessage());
            verify(console).writeln(eq(expectedMessage), eq(MessageSeverity.HIGH));
            mapper.verifyNoInteractions();
        }
    }

    @Test
    void parse_whenProjectIsMissing_setsUnknownAttributes(@TempDir Path appDir) throws IOException {
        Path json = Files.createFile(appDir.resolve("noproj.json"));

        IstanbulSourceFileCoverageDto dto = sourceDto("some\\weird\\path\\noproj.js", null);

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
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
    void parse_whenSourceIsOutsideProjectRoot_usesRawPathForResProjPath(@TempDir Path appDir) throws IOException {
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

    @Test
    void parse_whenApplicationDirectoryIsMissing_reportsListingFailure(@TempDir Path tempDir) {
        Path missingDirectory = tempDir.resolve("missing");

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> StaticCoverageParser.parse(missingDirectory, context, null));

        String expectedMessage = NLS.getFormatted(CommonMessages.FAILED_TO_LIST_STATIC_COVERAGE_JSON_FILES,
                missingDirectory);
        assertEquals(expectedMessage, ex.getMessage());
        verify(console).writeln(eq(expectedMessage), eq(MessageSeverity.HIGH));
    }

    @Test
    void parse_whenSourceFileHasNoExtension_usesFileNameForItemIdentity(@TempDir Path appDir)
            throws IOException {
        Path json = Files.createFile(appDir.resolve("coverage.json"));
        IstanbulSourceFileCoverageDto dto = sourceDto("/proj/root/README", project("demo", "/proj/root"));

        try (MockedStatic<IstanbulJsonCoverageReader> reader = mockStatic(IstanbulJsonCoverageReader.class);
             MockedStatic<IstanbulFunctionLineMapper> mapper = mockStatic(IstanbulFunctionLineMapper.class)) {
            reader.when(() -> IstanbulJsonCoverageReader.read(json)).thenReturn(dto);
            mapper.when(() -> IstanbulFunctionLineMapper.map(dto)).thenReturn(List.of());

            List<FileCoverage> result = StaticCoverageParser.parse(appDir, context, null);

            CoverableItemNode fileItem = result.get(0).getStaticItems().get(0);
            assertEquals("README", fileItem.getDisplayName());
            assertEquals("README", fileItem.getItemId());
        }
    }

    private static IstanbulSourceFileCoverageDto sourceDto(String path, IstanbulProjectDto project) {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(path);
        dto.setProject(project);
        return dto;
    }

    private static Field loggerHandlerField() throws NoSuchFieldException {
        Field handlerField = ParasoftLogger.class.getDeclaredField("_handler");
        handlerField.setAccessible(true);
        return handlerField;
    }

    private static void writeManifest(Path sessionDirectory, String schemaVersion) throws IOException {
        Files.writeString(sessionDirectory.resolve("version.json"), """
                {
                  "schemaVersion": "%s",
                  "toolVersion": "6.0.3-1"
                }
                """.formatted(schemaVersion));
    }

    private static IstanbulProjectDto project(String name, String root) {
        IstanbulProjectDto p = new IstanbulProjectDto();
        p.setName(name);
        p.setRoot(root);
        return p;
    }
}


