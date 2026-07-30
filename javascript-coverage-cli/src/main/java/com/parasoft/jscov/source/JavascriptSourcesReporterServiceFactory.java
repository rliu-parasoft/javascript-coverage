package com.parasoft.jscov.source;

import com.parasoft.xtest.reports.publish.sources.SourcesReporterService;
import com.parasoft.xtest.reports.publish.sources.SourcesReporterServiceFactory;
import com.parasoft.xtest.results.api.IResultReporterService;
import com.parasoft.xtest.common.services.IParasoftServiceWithDispose;
import com.parasoft.xtest.services.api.IParasoftServiceContext;
import com.parasoft.xtest.services.api.diagnostics.IDiagnosableService;

public final class JavascriptSourcesReporterServiceFactory extends SourcesReporterServiceFactory
{
    @Override
    protected IResultReporterService createService(IParasoftServiceContext context)
    {
        return new JavascriptSourcesReporterService(context);
    }

    static final class JavascriptSourcesReporterService extends SourcesReporterService
            implements IResultReporterService, IDiagnosableService, IParasoftServiceWithDispose
    {
        JavascriptSourcesReporterService(IParasoftServiceContext context)
        {
            super(context);
        }

        @Override
        protected boolean isLicenseEnabled(IParasoftServiceContext context)
        {
            return true;
        }
    }
}
