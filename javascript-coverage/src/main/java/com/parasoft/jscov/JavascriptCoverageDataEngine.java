package com.parasoft.jscov;

import com.parasoft.xtest.common.api.console.IConsole;
import com.parasoft.xtest.common.api.progress.IProgressMonitor;
import com.parasoft.xtest.common.api.telemetry.ITelemetryConfiguration;
import com.parasoft.xtest.coverage.all.api.*;
import com.parasoft.xtest.services.api.INamedControllerInfo;
import com.parasoft.xtest.services.api.license.ILicenseDefinitionProvider;
import com.parasoft.xtest.testcases.api.TestCaseIdentifier;

import java.nio.file.Path;
import java.util.*;

public class JavascriptCoverageDataEngine implements ICoverageDataEngine
{
    private static final INamedControllerInfo CONTROLLER_INFO = new ControllerInfo();

    @Override
    public INamedControllerInfo getEngineInfo()
    {
        return CONTROLLER_INFO;
    }

    @Override
    public CommandLineArgument[] getEngineOptions()
    {
        return new CommandLineArgument[0];
    }

    @Override
    public Iterator<ServiceDeclaration> getDeclaredServices()
    {
        return null;
    }

    @Override
    public ITelemetryConfiguration getTelemetryConfiguration()
    {
        return null;
    }

    @Override
    public ILicenseDefinitionProvider getLicenseDefinitionProvider()
    {
        return null;
    }

    @Override
    public boolean verifyOptions(ICoverageOptions options, IConsole console)
    {
        return true;
    }

    @Override
    public IApplicationCoverageData scanApplication(Path appToScan, ICoverageContext context, IProgressMonitor monitor)
    {
        return null;
    }

    @Override
    public IBinaryCoverageData scanRuntimeData(Path runtimeDataPath, ICoverageContext context, IProgressMonitor monitor)
    {
        return null;
    }

    @Override
    public IRuntimeCoverageData processRuntimeData(Path runtimeDataPath, ICoverageContext context, IProgressMonitor monitor)
    {
        return null;
    }

    @Override
    public String getTestPath(TestCaseIdentifier identifier, ICoverageContext context)
    {
        return null;
    }

    @Override
    public String getCLICommandName()
    {
        return "java -jar jscov.jar";
    }


    private static final class ControllerInfo implements INamedControllerInfo
    {
        @Override
        public String getId()
        {
            return "jsc";
        }

        @Override
        public String getName()
        {
            return "JSC";
        }

        @Override
        public String getDisplayName()
        {
            return "Javascript Coverage";
        }

        @Override
        public String getVersion()
        {
            return "1.0.0";
        }
    }
}
