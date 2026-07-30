package com.parasoft.jscov.coverage;

import com.parasoft.jscov.JavascriptCoverageLogger;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.api.IFileTestableInput;
import com.parasoft.xtest.common.api.ITestableInput;
import com.parasoft.xtest.common.api.locations.LocationsException;
import com.parasoft.xtest.common.locations.LocationUtil;
import com.parasoft.xtest.common.nls.NLS;
import com.parasoft.xtest.coverage.all.api.IApplicationCoverageData;
import com.parasoft.xtest.coverage.api.results.IDynamicCoverageInfo;
import com.parasoft.xtest.coverage.api.results.ILineCoverageInfoBuilder;
import com.parasoft.xtest.coverage.api.results.IStaticCoverageInfo;

import java.util.*;

public final class ApplicationCoverageData implements IApplicationCoverageData {
    private final List<ITestableInput> acceptedInputs = new ArrayList<>();
    private final Map<String, FileCoverage> indexByReferenceId = new HashMap<>();

    public ApplicationCoverageData(List<FileCoverage> fileCoverages) {
        for (FileCoverage fileCoverage : fileCoverages) {
            ITestableInput input;
            try {
                input = LocationUtil.createTestableInput(fileCoverage.getLocationProperties());
            } catch (LocationsException e) {
                JavascriptCoverageLogger.getLogger().warn(NLS.getFormatted(CommonMessages.FAILED_TO_CREATE_ITESTABLEINPUT_FROM_PROPERTIES, fileCoverage.getReferenceId()));
                continue;
            }
            acceptedInputs.add(input);
            indexByReferenceId.put(fileCoverage.getReferenceId(), fileCoverage);
        }
    }

    @Override
    public Iterator<ITestableInput> getAcceptedTestableInputs() {
        return acceptedInputs.iterator();
    }

    @Override
    public String getApplicationReferenceId(ITestableInput input) {
        return resolveReferenceId(input);
    }

    @Override
    public List<IStaticCoverageInfo> getStaticCoverageResults(ITestableInput input, ILineCoverageInfoBuilder builder) {
        FileCoverage fileCoverage = indexByReferenceId.get(resolveReferenceId(input));
        if (fileCoverage == null) {
            return Collections.emptyList();
        }

        CoverageBuilderAdapter.addStaticCoverage(builder, fileCoverage.getStaticItems());
        return builder.getStaticInfos();
    }

    @Override
    public List<IDynamicCoverageInfo> getDynamicCoverageResults(ITestableInput input, ILineCoverageInfoBuilder builder) {
        return Collections.emptyList();
    }

    @Override
    public int getUnmatchedBinariesCount() {
        return 0;
    }

    private static String resolveReferenceId(ITestableInput input) {
        if (input instanceof IFileTestableInput) {
            return ((IFileTestableInput) input).getFileLocation().toURI().toString();
        }

        return input.getName();
    }
}
