package com.parasoft.jscov.coverage;

import com.parasoft.xtest.common.api.ITestableInput;
import com.parasoft.xtest.coverage.api.results.IDynamicCoverageInfo;
import com.parasoft.xtest.coverage.api.results.ILineCoverageInfoBuilder;
import com.parasoft.xtest.coverage.api.results.IStaticCoverageInfo;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Iterator;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ApplicationCoverageDataTest {

    @Test
    void getApplicationReferenceId_resolvesAcceptedInputToFileReferenceId(@TempDir Path tempDir) throws IOException {
        Path source = Files.createFile(tempDir.resolve("app.js"));
        String referenceId = source.toFile().toURI().toString();
        ApplicationCoverageData data = new ApplicationCoverageData(List.of(
                new FileCoverage(source.toFile(), referenceId, List.of())));

        Iterator<ITestableInput> inputs = data.getAcceptedTestableInputs();

        assertTrue(inputs.hasNext());
        ITestableInput input = inputs.next();
        assertEquals(referenceId, data.getApplicationReferenceId(input));
    }

    @Test
    void getStaticCoverageResults_providesStaticInfosForKnownInput(@TempDir Path tempDir) throws IOException {
        Path source = Files.createFile(tempDir.resolve("app.js"));
        String referenceId = source.toFile().toURI().toString();
        CoverableItemNode item = new CoverableItemNode("app", "app.js", List.of(4), List.of());
        ApplicationCoverageData data = new ApplicationCoverageData(List.of(
                new FileCoverage(source.toFile(), referenceId, List.of(item))));
        ITestableInput input = data.getAcceptedTestableInputs().next();
        ILineCoverageInfoBuilder builder = mock(ILineCoverageInfoBuilder.class);
        List<IStaticCoverageInfo> expected = List.of(mock(IStaticCoverageInfo.class));
        when(builder.getStaticInfos()).thenReturn(expected);

        List<IStaticCoverageInfo> result = data.getStaticCoverageResults(input, builder);

        assertEquals(expected, result);
    }

    @Test
    void getStaticCoverageResults_emptyForUnknownInput() {
        ApplicationCoverageData data = new ApplicationCoverageData(List.of());
        ITestableInput input = mock(ITestableInput.class);
        when(input.getName()).thenReturn("unknown");
        ILineCoverageInfoBuilder builder = mock(ILineCoverageInfoBuilder.class);

        assertTrue(data.getStaticCoverageResults(input, builder).isEmpty());
    }

    @Test
    void getDynamicCoverageResults_emptyForUnknownInput() {
        ApplicationCoverageData data = new ApplicationCoverageData(List.of());
        ITestableInput input = mock(ITestableInput.class);
        when(input.getName()).thenReturn("unknown");
        ILineCoverageInfoBuilder builder = mock(ILineCoverageInfoBuilder.class);

        List<IDynamicCoverageInfo> dynamic = data.getDynamicCoverageResults(input, builder);

        assertTrue(dynamic.isEmpty());
    }

    @Test
    void getUnmatchedBinariesCount_zeroForUnknownInput() {
        ApplicationCoverageData data = new ApplicationCoverageData(List.of());

        assertEquals(0, data.getUnmatchedBinariesCount());
    }

    @Test
    void getAcceptedTestableInputs_skipsInvalidAndKeepsValidLocation(@TempDir Path tempDir) throws IOException {
        Path source = Files.createFile(tempDir.resolve("app.js"));
        String referenceId = source.toFile().toURI().toString();
        FileCoverage invalid = new FileCoverage(new java.io.File("invalid.js"), "::::", List.of());
        FileCoverage valid = new FileCoverage(source.toFile(), referenceId, List.of());

        ApplicationCoverageData data = new ApplicationCoverageData(List.of(invalid, valid));

        Iterator<ITestableInput> inputs = data.getAcceptedTestableInputs();
        assertTrue(inputs.hasNext());
        assertEquals(referenceId, data.getApplicationReferenceId(inputs.next()));
        assertFalse(inputs.hasNext());
    }
}
