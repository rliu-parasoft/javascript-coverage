package com.parasoft.jscov.coverage.istanbul;


import com.parasoft.jscov.coverage.istanbul.dto.FunctionLineCoverageDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto;

import java.util.*;

public final class IstanbulFunctionLineMapper
{
    private static final String GLOBAL_FN_NAME = "<global>";

    public static List<FunctionLineCoverageDto> map(IstanbulSourceFileCoverageDto istanbulSourceFileCoverageDto)
    {
        Objects.requireNonNull(istanbulSourceFileCoverageDto, "istanbulSourceFileCoverageDto must no be null");

        String sourceFilePath = istanbulSourceFileCoverageDto.getPath();
        Objects.requireNonNull(sourceFilePath, "sourceFilePath must no be null");

        return collectFunctionLines(sourceFilePath, istanbulSourceFileCoverageDto);
    }

    private static List<FunctionLineCoverageDto> collectFunctionLines(String path, IstanbulSourceFileCoverageDto fileCoverage)
    {
        Map<String, IstanbulSourceFileCoverageDto.FunctionDto> fnMap = safeMap(fileCoverage.getFnMap());
        Map<String, IstanbulSourceFileCoverageDto.RangeDto> statementMap = safeMap(fileCoverage.getStatementMap());
        List<FunctionLineCoverageDto> functionLines = new ArrayList<>();
        Set<String> matchedStatementIds = new java.util.HashSet<>();

        for (Map.Entry<String, IstanbulSourceFileCoverageDto.FunctionDto> fnEntry : fnMap.entrySet()) {
            IstanbulSourceFileCoverageDto.FunctionDto functionDto = fnEntry.getValue();
            if (functionDto == null) {
                continue;
            }

            Set<Integer> lines = new TreeSet<>();
            for (Map.Entry<String, IstanbulSourceFileCoverageDto.RangeDto> statementEntry : statementMap.entrySet()) {
                IstanbulSourceFileCoverageDto.RangeDto statementRange = statementEntry.getValue();
                if (isStatementInsideFunction(statementRange, functionDto)) {
                    Integer line = getStartLine(statementRange);
                    if (line != null) {
                        lines.add(line);
                        matchedStatementIds.add(statementEntry.getKey());
                    }
                }
            }

            String fnName = functionDto.getName() != null ? functionDto.getName() : "(unknown_function_name)";
            functionLines.add(new FunctionLineCoverageDto(buildFnId(path, fnName), fnName, lines));
        }

        Set<Integer> globalLines = new TreeSet<>();
        for (Map.Entry<String, IstanbulSourceFileCoverageDto.RangeDto> statementEntry : statementMap.entrySet()) {
            if (matchedStatementIds.contains(statementEntry.getKey())) {
                continue;
            }

            Integer line = getStartLine(statementEntry.getValue());
            if (line != null) {
                globalLines.add(line);
            }
        }
        if (!globalLines.isEmpty()) {
            functionLines.add(new FunctionLineCoverageDto(buildFnId(path, GLOBAL_FN_NAME), GLOBAL_FN_NAME, globalLines));
        }

        functionLines.sort(Comparator
                .comparing((FunctionLineCoverageDto dto) -> !GLOBAL_FN_NAME.equals(dto.getFnName()))
                .thenComparingInt(IstanbulFunctionLineMapper::firstLineOrMax)
                .thenComparing(FunctionLineCoverageDto::getFnName));

        return Collections.unmodifiableList(functionLines);
    }

    private static String buildFnId(String path, String fnName)
    {
        return extractFileName(path) + "#" + fnName;
    }

    private static String extractFileName(String path)
    {
        if ((path == null) || path.isBlank()) {
            return "(unknown_file)";
        }

        int lastSlash = path.lastIndexOf('/');
        int lastBackslash = path.lastIndexOf('\\');
        int splitPos = Math.max(lastSlash, lastBackslash);
        if (splitPos < 0 || splitPos == path.length() - 1) {
            return path;
        }
        return path.substring(splitPos + 1);
    }

    private static int firstLineOrMax(FunctionLineCoverageDto dto)
    {
        if ((dto == null) || dto.getLines().isEmpty()) {
            return Integer.MAX_VALUE;
        }
        return dto.getLines().iterator().next();
    }

    private static Integer getStartLine(IstanbulSourceFileCoverageDto.RangeDto rangeDto)
    {
        if ((rangeDto == null) || (rangeDto.getStart() == null)) {
            return null;
        }
        return rangeDto.getStart().getLine();
    }

    private static boolean isStatementInsideFunction(
            IstanbulSourceFileCoverageDto.RangeDto statement,
            IstanbulSourceFileCoverageDto.FunctionDto functionDto)
    {
        // If data is missing, we cannot judge it, so return false.
        if ((statement == null) || (functionDto == null)) {
            return false;
        }

        // Only use function body range (loc). Exclude declaration/signature range (decl).
        IstanbulSourceFileCoverageDto.PositionDto functionStart = getStart(functionDto.getLoc());
        IstanbulSourceFileCoverageDto.PositionDto functionEnd = getEnd(functionDto.getLoc());

        IstanbulSourceFileCoverageDto.PositionDto statementStart = getStart(statement);
        IstanbulSourceFileCoverageDto.PositionDto statementEnd = getEnd(statement);

        // We at least need line numbers on both function and statement ranges.
        if (!hasLine(functionStart) || !hasLine(functionEnd) ||
                !hasLine(statementStart) || !hasLine(statementEnd)) {
            return false;
        }

        // First do a quick line check: statement must stay inside function lines.
        if (compareLine(statementStart, functionStart) < 0 ||
                compareLine(statementEnd, functionEnd) > 0) {
            return false;
        }

        // If they start on the same line and both columns are known, make sure statement does not start earlier.
        if (isSameLine(statementStart, functionStart) &&
                hasColumn(statementStart) &&
                hasColumn(functionStart) &&
                compareColumn(statementStart, functionStart) < 0) {
            return false;
        }

        // If they end on the same line and both columns are known, make sure statement does not end later.
        if (isSameLine(statementEnd, functionEnd) &&
                hasColumn(statementEnd) &&
                hasColumn(functionEnd) &&
                compareColumn(statementEnd, functionEnd) > 0) {
            return false;
        }

        return true;
    }

    private static IstanbulSourceFileCoverageDto.PositionDto getStart(IstanbulSourceFileCoverageDto.RangeDto rangeDto)
    {
        return rangeDto == null ? null : rangeDto.getStart();
    }

    private static IstanbulSourceFileCoverageDto.PositionDto getEnd(IstanbulSourceFileCoverageDto.RangeDto rangeDto)
    {
        return rangeDto == null ? null : rangeDto.getEnd();
    }

    private static boolean hasLine(IstanbulSourceFileCoverageDto.PositionDto positionDto)
    {
        return (positionDto != null) &&
                (positionDto.getLine() != null);
    }

    private static boolean hasColumn(IstanbulSourceFileCoverageDto.PositionDto positionDto)
    {
        return (positionDto != null) &&
                (positionDto.getColumn() != null);
    }

    private static boolean isSameLine(
            IstanbulSourceFileCoverageDto.PositionDto p1,
            IstanbulSourceFileCoverageDto.PositionDto p2)
    {
        return compareLine(p1, p2) == 0;
    }

    private static int compareLine(
            IstanbulSourceFileCoverageDto.PositionDto p1,
            IstanbulSourceFileCoverageDto.PositionDto p2)
    {
        return Integer.compare(p1.getLine(), p2.getLine());
    }

    private static int compareColumn(
            IstanbulSourceFileCoverageDto.PositionDto p1,
            IstanbulSourceFileCoverageDto.PositionDto p2)
    {
        return Integer.compare(p1.getColumn(), p2.getColumn());
    }

    private static <K, V> Map<K, V> safeMap(Map<K, V> map)
    {
        return map == null ? Collections.emptyMap() : map;
    }
}
