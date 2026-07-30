package com.parasoft.jscov.coverage.istanbul;

import com.parasoft.jscov.coverage.istanbul.dto.FunctionLineCoverageDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.FunctionDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.PositionDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.RangeDto;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class IstanbulFunctionLineMapperTest {

    private static final String PATH = "E:/proj/src/math.ts";
    private static final String FILE_NAME = "math.ts";

    @Test
    void map_nullDto_throwsNullPointerException() {
        assertThrows(NullPointerException.class, () -> IstanbulFunctionLineMapper.map(null));
    }

    @Test
    void map_nullPath_throwsNullPointerException() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        assertThrows(NullPointerException.class, () -> IstanbulFunctionLineMapper.map(dto));
    }

    @Test
    void map_noFnMapNoStatementMap_returnsEmptyList() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertTrue(result.isEmpty());
    }

    @Test
    void map_statementsWithoutFunctions_areGroupedUnderGlobal() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        dto.setStatementMap(Map.of(
                "0", range(3, 0, 3, 10),
                "1", range(5, 0, 5, 20)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(1, result.size());
        FunctionLineCoverageDto global = result.get(0);
        assertEquals("<global>", global.getFnName());
        assertEquals(FILE_NAME + "#<global>", global.getFnId());
        assertEquals(List.of(3, 5), List.copyOf(global.getLines()));
    }

    @Test
    void map_assignsStatementsToEnclosingFunctionAndSortsResults() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);

        // function "beta" body: lines 2..4
        // function "alpha" body: lines 8..12
        // A trailing global statement on line 20 not inside any function.
        Map<String, FunctionDto> fnMap = new LinkedHashMap<>();
        fnMap.put("f0", function("beta", range(2, 0, 4, 1)));
        fnMap.put("f1", function("alpha", range(8, 0, 12, 1)));
        dto.setFnMap(fnMap);

        Map<String, RangeDto> stmts = new LinkedHashMap<>();
        stmts.put("s0", range(3, 4, 3, 10));   // in beta
        stmts.put("s1", range(9, 4, 9, 10));   // in alpha
        stmts.put("s2", range(10, 4, 10, 8));  // in alpha
        stmts.put("s3", range(20, 0, 20, 5));  // global
        dto.setStatementMap(stmts);

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(3, result.size());
        // Global first (its comparator key is false < true), then functions by firstLine.
        assertEquals("<global>", result.get(0).getFnName());
        assertEquals(FILE_NAME + "#<global>", result.get(0).getFnId());
        assertEquals(List.of(20), List.copyOf(result.get(0).getLines()));

        assertEquals("beta", result.get(1).getFnName());
        assertEquals(FILE_NAME + "#beta", result.get(1).getFnId());
        assertEquals(List.of(3), List.copyOf(result.get(1).getLines()));

        assertEquals("alpha", result.get(2).getFnName());
        assertEquals(FILE_NAME + "#alpha", result.get(2).getFnId());
        assertEquals(List.of(9, 10), List.copyOf(result.get(2).getLines()));
    }

    @Test
    void map_returnedListIsUnmodifiable() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        dto.setStatementMap(Map.of("0", range(1, 0, 1, 5)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertThrows(UnsupportedOperationException.class,
                () -> result.add(new FunctionLineCoverageDto("x", "x", java.util.Set.of())));
    }

    @Test
    void map_statementOutsideFunctionLines_isExcluded() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        dto.setFnMap(Map.of("f0", function("fn", range(5, 0, 10, 0))));
        dto.setStatementMap(Map.of(
                "s0", range(4, 0, 4, 5),   // before function start line
                "s1", range(11, 0, 11, 5)  // after function end line
        ));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        // Function has no statements → still emitted with empty lines.
        // Statements go to <global> group.
        assertEquals(2, result.size());
        FunctionLineCoverageDto global = result.get(0);
        assertEquals("<global>", global.getFnName());
        assertEquals(List.of(4, 11), List.copyOf(global.getLines()));

        FunctionLineCoverageDto fn = result.get(1);
        assertEquals("fn", fn.getFnName());
        assertTrue(fn.getLines().isEmpty());
    }

    @Test
    void map_sameLineColumnBoundaries_excludeStatementsOutsideColumnRange() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        // Function body single line 2, columns 10..30.
        dto.setFnMap(Map.of("f0", function("fn", range(2, 10, 2, 30))));
        dto.setStatementMap(Map.of(
                "s0", range(2, 5, 2, 15),   // starts before fn start column → excluded
                "s1", range(2, 12, 2, 35),  // ends after fn end column → excluded
                "s2", range(2, 12, 2, 20)   // fully inside → included
        ));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        // Statements s0 and s1 fall into global (they still have valid line info).
        assertEquals(2, result.size());
        assertEquals("<global>", result.get(0).getFnName());
        assertEquals(List.of(2), List.copyOf(result.get(0).getLines()));
        assertEquals("fn", result.get(1).getFnName());
        assertEquals(List.of(2), List.copyOf(result.get(1).getLines()));
    }

    @Test
    void map_missingPositionData_treatsStatementAsUnmatched() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);

        // Function loc missing end position → containment check fails, statement falls to global.
        FunctionDto fn = function("fn", null);
        RangeDto locMissingEnd = new RangeDto();
        locMissingEnd.setStart(pos(1, 0));
        fn.setLoc(locMissingEnd);

        dto.setFnMap(Map.of("f0", fn));
        dto.setStatementMap(Map.of("s0", range(2, 0, 2, 5)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(2, result.size());
        assertEquals("<global>", result.get(0).getFnName());
        assertEquals(List.of(2), List.copyOf(result.get(0).getLines()));
        assertEquals("fn", result.get(1).getFnName());
        assertTrue(result.get(1).getLines().isEmpty());
    }

    @Test
    void map_statementWithNullStartLine_isIgnored() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);

        RangeDto missingStartLine = new RangeDto();
        PositionDto start = new PositionDto();
        start.setColumn(0); // line is null
        missingStartLine.setStart(start);
        missingStartLine.setEnd(pos(3, 5));

        dto.setStatementMap(Map.of("s0", missingStartLine));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertTrue(result.isEmpty());
    }

    @Test
    void map_nullFunctionName_fallsBackToUnknownFunctionName() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        dto.setFnMap(Map.of("f0", function(null, range(1, 0, 3, 0))));
        dto.setStatementMap(Map.of("s0", range(2, 0, 2, 5)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(1, result.size());
        assertEquals("(unknown_function_name)", result.get(0).getFnName());
        assertEquals(FILE_NAME + "#(unknown_function_name)", result.get(0).getFnId());
    }

    @Test
    void map_nullFunctionValueInMap_isSkipped() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        Map<String, FunctionDto> fnMap = new HashMap<>();
        fnMap.put("f0", null);
        dto.setFnMap(fnMap);
        dto.setStatementMap(Map.of("s0", range(2, 0, 2, 5)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(1, result.size());
        assertEquals("<global>", result.get(0).getFnName());
    }

    @Test
    void map_blankPath_usesUnknownFileInFnId() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath("   ");
        dto.setFnMap(Map.of("f0", function("fn", range(1, 0, 3, 0))));
        dto.setStatementMap(Map.of("s0", range(2, 0, 2, 5)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals("(unknown_file)#fn", result.get(0).getFnId());
    }

    @Test
    void map_backslashPath_extractsFileName() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath("C:\\proj\\src\\app.js");
        dto.setStatementMap(Map.of("s0", range(1, 0, 1, 5)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals("app.js#<global>", result.get(0).getFnId());
    }

    @Test
    void map_pathWithoutSeparator_usesFullPathAsFileName() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath("app.js");
        dto.setStatementMap(Map.of("s0", range(1, 0, 1, 5)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals("app.js#<global>", result.get(0).getFnId());
    }

    @Test
    void map_pathEndingWithSeparator_usesFullPathAsFileName() {
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        String path = "E:/proj/src/";
        dto.setPath(path);
        dto.setStatementMap(Map.of("s0", range(1, 0, 1, 5)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(path + "#<global>", result.get(0).getFnId());
    }

    @Test
    void map_statementEndColumnNull_onFunctionEndLine_isIncluded() {
        // Real Istanbul JSON frequently emits `end.column: null`. When the statement ends on the
        // same line as the function but its end column is unknown, the column-based exclusion
        // must be skipped and the statement must still be attributed to the function.
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        dto.setFnMap(Map.of("f0", function("fn", range(2, 10, 2, 30))));

        RangeDto stmt = new RangeDto();
        stmt.setStart(pos(2, 12));
        stmt.setEnd(pos(2, null));
        dto.setStatementMap(Map.of("s0", stmt));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(1, result.size());
        assertEquals("fn", result.get(0).getFnName());
        assertEquals(List.of(2), List.copyOf(result.get(0).getLines()));
    }

    @Test
    void map_functionEndColumnNull_onSameEndLine_includesStatement() {
        // If the function's own end column is null (as in real Istanbul output), the same-line
        // end-column exclusion is skipped and any statement that fits by line stays inside.
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);

        RangeDto fnLoc = new RangeDto();
        fnLoc.setStart(pos(2, 10));
        fnLoc.setEnd(pos(2, null));
        dto.setFnMap(Map.of("f0", function("fn", fnLoc)));

        // Statement ends far to the right of where the function would end; must still be included.
        dto.setStatementMap(Map.of("s0", range(2, 12, 2, 100)));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(1, result.size());
        assertEquals("fn", result.get(0).getFnName());
        assertEquals(List.of(2), List.copyOf(result.get(0).getLines()));
    }

    @Test
    void map_startColumnNull_onSameStartLine_includesStatement() {
        // Mirror of the end-column test but for start columns: null start columns must not
        // trigger the "starts earlier than function" exclusion.
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        dto.setFnMap(Map.of("f0", function("fn", range(2, 10, 4, 0))));

        RangeDto stmt = new RangeDto();
        stmt.setStart(pos(2, null));
        stmt.setEnd(pos(2, 20));
        dto.setStatementMap(Map.of("s0", stmt));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        assertEquals(1, result.size());
        assertEquals("fn", result.get(0).getFnName());
        assertEquals(List.of(2), List.copyOf(result.get(0).getLines()));
    }

    @Test
    void map_nullStatementRange_isIgnored() {
        // Exercises the `statement == null` early-return branch in isStatementInsideFunction
        // and the null-safe getStartLine path in the global collection loop.
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        dto.setFnMap(Map.of("f0", function("fn", range(1, 0, 5, 0))));

        Map<String, RangeDto> stmts = new HashMap<>();
        stmts.put("s0", null);
        stmts.put("s1", range(2, 0, 2, 5)); // real one so we still assert normal path works
        dto.setStatementMap(stmts);

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        // Only the real statement contributes; the null one is silently skipped everywhere.
        assertEquals(1, result.size());
        assertEquals("fn", result.get(0).getFnName());
        assertEquals(List.of(2), List.copyOf(result.get(0).getLines()));
    }

    @Test
    void map_statementWithNullEndLine_isNotInsideFunction() {
        // Exercises the `hasLine(statementEnd)` false branch (symmetric to the start-line case).
        IstanbulSourceFileCoverageDto dto = new IstanbulSourceFileCoverageDto();
        dto.setPath(PATH);
        dto.setFnMap(Map.of("f0", function("fn", range(1, 0, 5, 0))));

        RangeDto missingEndLine = new RangeDto();
        missingEndLine.setStart(pos(2, 0));
        PositionDto end = new PositionDto();
        end.setColumn(5); // line is null
        missingEndLine.setEnd(end);
        dto.setStatementMap(Map.of("s0", missingEndLine));

        List<FunctionLineCoverageDto> result = IstanbulFunctionLineMapper.map(dto);

        // Statement fails the line-completeness check, so it's not inside the function
        // and falls through to <global> (its start line 2 is still known).
        assertEquals(2, result.size());
        assertEquals("<global>", result.get(0).getFnName());
        assertEquals(List.of(2), List.copyOf(result.get(0).getLines()));
        assertEquals("fn", result.get(1).getFnName());
        assertTrue(result.get(1).getLines().isEmpty());
    }

    private static PositionDto pos(Integer line, Integer column) {
        PositionDto p = new PositionDto();
        p.setLine(line);
        p.setColumn(column);
        return p;
    }

    private static RangeDto range(Integer startLine, Integer startCol, Integer endLine, Integer endCol) {
        RangeDto r = new RangeDto();
        r.setStart(pos(startLine, startCol));
        r.setEnd(pos(endLine, endCol));
        return r;
    }

    private static FunctionDto function(String name, RangeDto loc) {
        FunctionDto fn = new FunctionDto();
        fn.setName(name);
        fn.setLoc(loc);
        return fn;
    }
}

