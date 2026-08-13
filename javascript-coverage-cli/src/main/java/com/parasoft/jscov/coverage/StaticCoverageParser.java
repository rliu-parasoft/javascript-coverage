package com.parasoft.jscov.coverage;

import com.parasoft.jscov.JavascriptCoverageDataEngine;
import com.parasoft.jscov.JavascriptCoverageLogger;
import com.parasoft.jscov.coverage.istanbul.IstanbulFunctionLineMapper;
import com.parasoft.jscov.coverage.istanbul.IstanbulJsonCoverageReader;
import com.parasoft.jscov.coverage.istanbul.dto.FunctionLineCoverageDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.api.MessageSeverity;
import com.parasoft.xtest.common.api.console.IConsole;
import com.parasoft.xtest.common.api.progress.IProgressMonitor;
import com.parasoft.xtest.common.nls.NLS;
import com.parasoft.xtest.coverage.all.api.ICoverageContext;
import com.parasoft.xtest.logging.api.ParasoftLogger;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.stream.Collectors;

public final class StaticCoverageParser {

    private static final ParasoftLogger logger = JavascriptCoverageLogger.getLogger();

    public static List<FileCoverage> parse(Path appToScan, ICoverageContext context, IProgressMonitor monitor) {
        IConsole console = context.getConsole();
        List<FileCoverage> parsedFileCoverages = new ArrayList<>();
        Map<StaticCoverageSchemaVersion, List<Path>> jsonFilesBySchemaVersion = listJsonFiles(appToScan, console);
        if (jsonFilesBySchemaVersion.isEmpty()) {
            String message = NLS.getFormatted(CommonMessages.NO_STATIC_COVERAGE_JSON_FILES_FOUND, appToScan.toAbsolutePath().toString());
            console.writeln(message, MessageSeverity.HIGH);
            throw new IllegalArgumentException(message);
        }
        for (Map.Entry<StaticCoverageSchemaVersion, List<Path>> entry : jsonFilesBySchemaVersion.entrySet()) {
            StaticCoverageSchemaVersion schemaVersion = entry.getKey();
            for (Path jsonFile : entry.getValue()) {
                logger.debug(NLS.getFormatted(CommonMessages.PARSING_STATIC_COVERAGE_JSON_FILE, jsonFile));
                IstanbulSourceFileCoverageDto istanbulSourceFileCoverageDto;
                try {
                    istanbulSourceFileCoverageDto = readCoverageJson(schemaVersion, jsonFile);
                } catch (Throwable thr) { // parasoft-suppress OWASP2021.A5.NCE "This is intentionally designed to prevent exceptions from bubbling up and causing the program to terminate."
                    String message = NLS.getFormatted(CommonMessages.FAILED_TO_PARSE_STATIC_COVERAGE_JSON, jsonFile);
                    console.writeln(message, MessageSeverity.HIGH);
                    logger.error(message, thr);
                    continue;
                }
                List<FunctionLineCoverageDto> lineMapByPath = IstanbulFunctionLineMapper.map(istanbulSourceFileCoverageDto);

                File sourceFile = new File(istanbulSourceFileCoverageDto.getPath());

                List<CoverableItemNode> functionItems = lineMapByPath.stream()
                        .map(StaticCoverageParser::toCoverableItem)
                        .collect(Collectors.toList());

                String fileName = sourceFile.getName();
                String fileDisplayName = stripExtension(fileName);
                CoverableItemNode fileItem = new CoverableItemNode(
                        fileDisplayName,
                        fileName,
                        Collections.emptyList(),
                        functionItems);

                FileCoverage parsedFileCoverage = new FileCoverage(
                        sourceFile,
                        sourceFile.toURI().toString(),
                        List.of(fileItem));
                addProjectAttributes(parsedFileCoverage, istanbulSourceFileCoverageDto);
                parsedFileCoverages.add(parsedFileCoverage);
            }
        }
        if (parsedFileCoverages.isEmpty()) {
            String message = NLS.getFormatted(CommonMessages.NO_VALID_STATIC_COVERAGE_JSON_FILES_FOUND_IN_DIRECTORY, appToScan.toAbsolutePath().toString());
            console.writeln(message, MessageSeverity.HIGH);
            throw new IllegalArgumentException(message);
        }
        return parsedFileCoverages;
    }

    private static Map<StaticCoverageSchemaVersion, List<Path>> listJsonFiles(Path appToScan, IConsole console) {
        Map<StaticCoverageSchemaVersion, List<Path>> jsonFilesBySchemaVersion = new EnumMap<>(StaticCoverageSchemaVersion.class);
        Map<String, SelectedStaticCoverageFile> preferredFilesByName = new HashMap<>();

        try {
            for (Path sessionDirectory : resolveSessionDirectories(appToScan)) {
                StaticCoverageSchemaVersion schemaVersion;
                try {
                    schemaVersion = StaticCoverageVersionManifestReader.read(sessionDirectory);
                } catch (IOException e) {
                    logger.debug(NLS.getFormatted(CommonMessages.SKIPPED_STATIC_COVERAGE_SESSION,
                            sessionDirectory, e.getMessage()));
                    continue;
                }

                try (var jsonFiles = Files.list(sessionDirectory)) {
                    List<Path> sessionJsonFiles = jsonFiles
                            .filter(Files::isRegularFile)
                            .filter(StaticCoverageParser::isCoverageJsonFile)
                            .sorted()
                            .toList();
                    for (Path jsonFile : sessionJsonFiles) {
                        addJsonFilePath(jsonFilesBySchemaVersion, preferredFilesByName, schemaVersion, jsonFile);
                    }
                }
            }
        } catch (IOException e) {
            String message = NLS.getFormatted(CommonMessages.FAILED_TO_LIST_STATIC_COVERAGE_JSON_FILES, appToScan);
            console.writeln(message, MessageSeverity.HIGH);
            throw new IllegalArgumentException(message, e);
        }
        return jsonFilesBySchemaVersion;
    }

    private static List<Path> resolveSessionDirectories(Path appToScan) throws IOException {
        if (Files.exists(appToScan.resolve("version.json")) || hasDirectCoverageJsonFile(appToScan)) {
            return List.of(appToScan);
        }
        try (var paths = Files.list(appToScan)) {
            return paths
                    .filter(Files::isDirectory)
                    .sorted()
                    .toList();
        }
    }

    private static boolean hasDirectCoverageJsonFile(Path directory) throws IOException {
        try (var paths = Files.list(directory)) {
            return paths
                    .filter(Files::isRegularFile)
                    .anyMatch(StaticCoverageParser::isCoverageJsonFile);
        }
    }

    private static boolean isCoverageJsonFile(Path path) {
        return path.getFileName().toString().endsWith(".json")
                && !path.getFileName().toString().equals("version.json");
    }

    private static void addJsonFilePath(
            Map<StaticCoverageSchemaVersion, List<Path>> jsonFilesBySchemaVersion,
            Map<String, SelectedStaticCoverageFile> preferredFilesByName,
            StaticCoverageSchemaVersion schemaVersion,
            Path jsonFile) {
        SelectedStaticCoverageFile selected = preferredFilesByName.get(jsonFile.getFileName().toString());
        if (selected == null) {
            addSelectedFile(jsonFilesBySchemaVersion, preferredFilesByName, schemaVersion, jsonFile);
            return;
        }
        if (selected.schemaVersion().getPriority() > schemaVersion.getPriority()) {
            logger.debug(NLS.getFormatted(
                    CommonMessages.SKIPPED_LOWER_STATIC_COVERAGE_SCHEMA_VERSION,
                    toLogPath(jsonFile), schemaVersion.getValue(), toLogPath(selected.path()),
                    selected.schemaVersion().getValue()));
            return;
        }
        if (selected.schemaVersion() == schemaVersion) {
            logger.debug(NLS.getFormatted(CommonMessages.SKIPPED_DUPLICATE_JSON_FILES,
                    jsonFile.getFileName(), toLogPath(jsonFile)));
            return;
        }
        jsonFilesBySchemaVersion.get(selected.schemaVersion()).remove(selected.path());
        logger.debug(NLS.getFormatted(
                CommonMessages.REPLACED_LOWER_STATIC_COVERAGE_SCHEMA_VERSION,
                toLogPath(selected.path()), selected.schemaVersion().getValue(), toLogPath(jsonFile),
                schemaVersion.getValue()));
        addSelectedFile(jsonFilesBySchemaVersion, preferredFilesByName, schemaVersion, jsonFile);
    }

    private static String toLogPath(Path coverageFile) {
        String pathStr = coverageFile.normalize().toString().replace('\\', '/');
        int index = pathStr.indexOf(JavascriptCoverageDataEngine.STATIC_COVERAGE_DIRECTORY.toString().replace('\\', '/'));
        if (index >= 0) {
            return pathStr.substring(index);
        }
        return pathStr;
    }

    private static void addSelectedFile(
            Map<StaticCoverageSchemaVersion, List<Path>> jsonFilesBySchemaVersion,
            Map<String, SelectedStaticCoverageFile> preferredFilesByName,
            StaticCoverageSchemaVersion schemaVersion,
            Path jsonFile) {
        jsonFilesBySchemaVersion.computeIfAbsent(schemaVersion, ignored -> new ArrayList<>()).add(jsonFile);
        preferredFilesByName.put(jsonFile.getFileName().toString(), new SelectedStaticCoverageFile(schemaVersion, jsonFile));
    }

    private record SelectedStaticCoverageFile(StaticCoverageSchemaVersion schemaVersion, Path path) { }

    private static IstanbulSourceFileCoverageDto readCoverageJson(
            StaticCoverageSchemaVersion schemaVersion, Path jsonFile) throws IOException {
        return switch (schemaVersion) {
            case V1_0 -> IstanbulJsonCoverageReader.read(jsonFile);
        };
    }

    private static void addProjectAttributes(FileCoverage fileCoverage, IstanbulSourceFileCoverageDto fileCoverageDto) {
        IstanbulSourceFileCoverageDto.IstanbulProjectDto project = fileCoverageDto.getProject();
        if (project != null && project.getName() != null && !project.getName().isBlank()) {
            fileCoverage.addAttribute("projId", project.getName());
            fileCoverage.addAttribute("project", project.getName());
            fileCoverage.addAttribute("projPath", "/" + project.getName());
        } else {
            fileCoverage.addAttribute("projId", "unknown");
            fileCoverage.addAttribute("project", "unknown");
            fileCoverage.addAttribute("projPath", "/unknown");
        }
        if (project != null && project.getRoot() != null && !project.getRoot().isBlank()) {
            fileCoverage.addAttribute("resProjPath", resolveResourcePath(project.getRoot(), fileCoverageDto.getPath()));
        } else {
            fileCoverage.addAttribute("resProjPath", fileCoverageDto.getPath().replace('\\', '/'));
        }
    }

    private static String resolveResourcePath(String projectRoot, String sourcePath) {
        Path rootPath = Path.of(projectRoot).toAbsolutePath().normalize();
        Path sourceFilePath = Path.of(sourcePath).toAbsolutePath().normalize();
        if (!sourceFilePath.startsWith(rootPath)) {
            return sourcePath.replace('\\', '/');
        }
        return rootPath.relativize(sourceFilePath).toString().replace('\\', '/');
    }

    private static CoverableItemNode toCoverableItem(FunctionLineCoverageDto dto) {
        return new CoverableItemNode(
                dto.getFnName(),
                dto.getFnId(),
                new ArrayList<>(dto.getLines()),
                Collections.emptyList());
    }

    private static String stripExtension(String fileName) {
        int lastDot = fileName.lastIndexOf('.');
        if (lastDot <= 0) {
            return fileName;
        }
        return fileName.substring(0, lastDot);
    }
}
