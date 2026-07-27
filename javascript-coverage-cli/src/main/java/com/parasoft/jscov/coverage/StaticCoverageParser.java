package com.parasoft.jscov.coverage;


import com.parasoft.xtest.common.api.progress.IProgressMonitor;
import com.parasoft.xtest.coverage.all.api.ICoverageContext;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

public final class StaticCoverageParser
{
    public static List<FileCoverage> parse(Path appToScan, ICoverageContext context, IProgressMonitor monitor)
    {
        Objects.requireNonNull(appToScan, "appToScan");

        Path baseDir = Files.isDirectory(appToScan) ? appToScan : appToScan.getParent();
        // TODO: Replace placeholder source path when implementing real parsing of static_coverage.json.
        Path sourcePath = (baseDir != null ? baseDir : appToScan).resolve("test.js");
        File sourceFile = sourcePath.toFile();

        // TODO: Replace fake coverable items when implementing real parsing of static_coverage.json.
        CoverableItemNode functionItem = new CoverableItemNode(
                "testFunction",
                "test.js:testFunction",
                List.of(1, 2, 3),
                Collections.emptyList());

        String fileName = resolveFileName(sourceFile, sourcePath.toString());
        String fileDisplayName = stripExtension(fileName);
        CoverableItemNode fileItem = new CoverableItemNode(
                fileDisplayName,
                fileName,
                Collections.emptyList(),
                List.of(functionItem));

        FileCoverage fileCoverage = new FileCoverage(
                sourceFile,
                sourceFile.toURI().toString(),
                List.of(fileItem));
        // TODO: Read from appToScan json file
        fileCoverage.addAttribute("projId", "js-babel");
        fileCoverage.addAttribute("project", "js-babel");
        fileCoverage.addAttribute("projPath", "/js-babel");
        fileCoverage.addAttribute("resProjPath", "src/" + resolveFileName(sourceFile, sourcePath.toString()));

        return List.of(fileCoverage);
    }

    private static String resolveFileName(File sourceFile, String sourcePath) {
        String name = sourceFile.getName();
        return name.isEmpty() ? sourcePath : name;
    }

    private static String stripExtension(String fileName) {
        int lastDot = fileName.lastIndexOf('.');
        if (lastDot <= 0) {
            return fileName;
        }
        return fileName.substring(0, lastDot);
    }
}
