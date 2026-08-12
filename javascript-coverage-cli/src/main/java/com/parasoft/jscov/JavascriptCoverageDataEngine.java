package com.parasoft.jscov;

import com.parasoft.jscov.coverage.ApplicationCoverageData;
import com.parasoft.jscov.coverage.FileCoverage;
import com.parasoft.jscov.coverage.StaticCoverageParser;
import com.parasoft.jscov.source.JavascriptSourcesReporterServiceFactory;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.api.MessageSeverity;
import com.parasoft.xtest.common.api.console.IConsole;
import com.parasoft.xtest.common.api.progress.IProgressMonitor;
import com.parasoft.xtest.common.api.telemetry.ITelemetryConfiguration;
import com.parasoft.xtest.coverage.all.api.*;
import com.parasoft.xtest.results.api.IResultReporterService;
import com.parasoft.xtest.services.api.INamedControllerInfo;
import com.parasoft.xtest.services.api.license.ILicenseDefinitionProvider;
import com.parasoft.xtest.testcases.api.TestCaseIdentifier;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

public class JavascriptCoverageDataEngine implements ICoverageDataEngine
{
    private static final INamedControllerInfo CONTROLLER_INFO = new ControllerInfo();
    private static final Path STATIC_COVERAGE_DIRECTORY = Path.of(".parasoft", "static-coverage");
    private static final String IMPACTED_UNSUPPORTED_MESSAGE =
            "JavaScript Coverage does not support the impacted command yet.";
    private static final String MERGE_UNSUPPORTED_MESSAGE =
            "JavaScript Coverage does not support the merge command yet.";
    private static final String FILTER_UNSUPPORTED_MESSAGE =
            "JavaScript Coverage does not support -include or -exclude yet.";
    private static final String RUNTIME_UNSUPPORTED_MESSAGE =
            "JavaScript Coverage does not support runtime coverage. Remove the -runtime option.";

    @Override
    public INamedControllerInfo getEngineInfo()
    {
        return CONTROLLER_INFO;
    }

    @Override
    public CommandLineArgument[] getEngineOptions()
    {
        // TODO: Declare future JSCov-specific options through getEngineOptions().
        return new CommandLineArgument[]{
            new CommandLineArgument(
                "-app",
                "%JSCOV_PROJECT_ROOT%",
                new ICoverageOptions.CoverageCommand[]{
                    ICoverageOptions.CoverageCommand.coverage,
                    ICoverageOptions.CoverageCommand.impacted
                },
                ArgumentType.Single,
                CommonMessages.APPLICATION_PARAMETER_DESCRIPTION)
        };
    }

    @Override
    public Iterator<ServiceDeclaration> getDeclaredServices()
    {
        List<ServiceDeclaration> services = new ArrayList<>();
        ServiceDeclaration sourcesReporterFactory = new ServiceDeclaration(
                IResultReporterService.Factory.class,
                JavascriptSourcesReporterServiceFactory.class,
                null);
        services.add(sourcesReporterFactory);
        return Collections.unmodifiableList(services).iterator();
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
        ICoverageOptions.CoverageCommand command = options.getCommand();
        if (ICoverageOptions.CoverageCommand.help.equals(command)) {
            return true;
        }

        if (ICoverageOptions.CoverageCommand.impacted.equals(command)) {
            // TODO: Remove this guard when JSCov implements impacted test analysis.
            return reject(console, IMPACTED_UNSUPPORTED_MESSAGE);
        }
        if (ICoverageOptions.CoverageCommand.merge.equals(command)) {
            // TODO: Remove this guard when JSCov implements report merging.
            return reject(console, MERGE_UNSUPPORTED_MESSAGE);
        }
        if (ICoverageOptions.CoverageCommand.testmap.equals(command)) {
            // JSCov permanently does not support the testmap command.
            return reject(console, CommonMessages.TESTMAP_UNSUPPORTED_MESSAGE);
        }
        if (ICoverageOptions.CoverageCommand.compare.equals(command)) {
            // JSCov permanently does not support the compare command.
            return reject(console, CommonMessages.COMPARE_UNSUPPORTED_MESSAGE);
        }

        if (options.getRuntimeCoverageData() != null) {
            // TODO: Remove this guard when JSCov implements runtime coverage.
            return reject(console, RUNTIME_UNSUPPORTED_MESSAGE);
        }
        if (hasValues(options.getIncludes()) || hasValues(options.getExcludes())) {
            // TODO: Remove this guard when static coverage scanning applies these filters.
            return reject(console, FILTER_UNSUPPORTED_MESSAGE);
        }

        Path applicationDirectory = options.getApplicationUnderTest();
        if (applicationDirectory != null
                && (applicationDirectory.toString().isEmpty()
                || !Files.isDirectory(applicationDirectory))) {
            return reject(console, CommonMessages.INVALID_APPLICATION_DIRECTORY_MESSAGE);
        }
        if (applicationDirectory != null
                && !Files.isDirectory(getStaticCoverageDirectory(applicationDirectory))) {
            return reject(console, CommonMessages.MISSING_STATIC_COVERAGE_DIRECTORY_MESSAGE);
        }

        // TODO: Add command-specific validation when JSCov supports additional CoverageRunner commands.
        return true;
    }

    private static boolean hasValues(String[] values)
    {
        return values != null && values.length > 0;
    }

    private static boolean reject(IConsole console, String message)
    {
        if (console != null) {
            console.writeln(message, MessageSeverity.HIGH);
        }
        return false;
    }

    @Override
    public IApplicationCoverageData scanApplication(Path appToScan, ICoverageContext context, IProgressMonitor monitor)
    {
        Objects.requireNonNull(appToScan, "appToScan must not null");
        List<FileCoverage> staticInputs = StaticCoverageParser.parse(
                getStaticCoverageDirectory(appToScan), context, monitor);

        return new ApplicationCoverageData(staticInputs);
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
        return "java -jar parasoft-jscov.jar";
    }

    private static Path getStaticCoverageDirectory(Path projectRoot)
    {
        return projectRoot.resolve(STATIC_COVERAGE_DIRECTORY);
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
