package com.parasoft.jscov.coverage;

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

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.stream.Collectors;

public final class StaticCoverageParser {

    public static List<FileCoverage> parse(Path appToScan, ICoverageContext context, IProgressMonitor monitor) {
        IConsole console = context.getConsole();
        List<FileCoverage> paredFileCoverages = new ArrayList<>();
        List<Path> jsonPaths = listJsonFiles(appToScan, console);
        if (jsonPaths.isEmpty()) {
            String message = NLS.getFormatted(CommonMessages.NO_ISTANBUL_JSON_FILES_FOUND, appToScan.toAbsolutePath().toString());
            console.writeln(message, MessageSeverity.HIGH);
            throw new IllegalArgumentException(message);
        }
        for (Path jsonFile : jsonPaths) {
            JavascriptCoverageLogger.getLogger().debug(NLS.getFormatted(CommonMessages.PARSING_ISTANBUL_JSON_FILE, jsonFile));
            IstanbulSourceFileCoverageDto istanbulSourceFileCoverageDto;
            try {
                istanbulSourceFileCoverageDto = IstanbulJsonCoverageReader.read(jsonFile);
            } catch (Throwable thr) {
                String message = NLS.getFormatted(CommonMessages.FAILED_TO_PARSE_ISTANBUL_JSON, jsonFile);
                console.writeln(message, MessageSeverity.HIGH);
                JavascriptCoverageLogger.getLogger().error(message, thr);
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
            paredFileCoverages.add(parsedFileCoverage);
        }
        if (paredFileCoverages.isEmpty()) {
            String message = NLS.getFormatted(CommonMessages.NO_VALID_ISTANBUL_JSON_FILES_FOUND_IN_DIRECTORY, appToScan.toAbsolutePath().toString());
            console.writeln(message, MessageSeverity.HIGH);
            throw new IllegalArgumentException(message);
        }
        return paredFileCoverages;
    }

    private static List<Path> listJsonFiles(Path appToScan, IConsole console) {
        List<Path> allJsonFiles;
        try (var jsonFiles = Files.walk(appToScan)) {
            allJsonFiles = jsonFiles
                    .filter(Files::isRegularFile)
                    .filter(path -> path.getFileName().toString().endsWith(".json"))
                    .sorted()
                    .toList();
        } catch (IOException e) {
            String message = NLS.getFormatted(CommonMessages.FAILED_TO_LIST_ISTANBUL_JSON_FILES, appToScan);
            console.writeln(message, MessageSeverity.HIGH);
            throw new IllegalArgumentException(message, e);
        }
        Map<String, List<Path>> byFileName = allJsonFiles.stream()
                .collect(Collectors.groupingBy(path -> path.getFileName().toString()));
        byFileName.forEach((name, paths) -> {
            if (paths.size() > 1) {
                String message = NLS.getFormatted(CommonMessages.SKIPPING_DUPLICATE_JSON_FILES ,name, paths.subList(1, paths.size()));
                JavascriptCoverageLogger.getLogger().debug(message);
            }
        });
        return byFileName.values().stream()
                .map(paths -> paths.get(0))
                .sorted()
                .toList();
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
