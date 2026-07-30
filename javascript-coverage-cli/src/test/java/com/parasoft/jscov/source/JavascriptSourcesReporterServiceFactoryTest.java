package com.parasoft.jscov.source;

import com.parasoft.xtest.results.api.IResultReporterService;
import com.parasoft.xtest.services.api.IParasoftServiceContext;
import org.junit.jupiter.api.Test;

import java.util.Properties;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class JavascriptSourcesReporterServiceFactoryTest {

    @Test
    void createsCoverageSourcesReporterService() {
        IParasoftServiceContext context = mock(IParasoftServiceContext.class);
        Properties preferences = new Properties();
        preferences.setProperty("dtp.url", "https://localhost:8443");
        when(context.getPreferences()).thenReturn(preferences);

        JavascriptSourcesReporterServiceFactory factory = new JavascriptSourcesReporterServiceFactory();
        IResultReporterService service = factory.getServiceUnsafe(context);

        try {
            assertInstanceOf(JavascriptSourcesReporterServiceFactory.JavascriptSourcesReporterService.class, service);
            assertFalse(((JavascriptSourcesReporterServiceFactory.JavascriptSourcesReporterService) service).isEnabled());
        } finally {
            factory.disposeService(context);
        }
    }

    @Test
    void enablesSourcePublishingWhenDtpPublishingIsConfigured() {
        IParasoftServiceContext context = mock(IParasoftServiceContext.class);
        Properties preferences = new Properties();
        preferences.setProperty("dtp.url", "https://localhost:8443");
        preferences.setProperty("report.dtp.publish", "true");
        preferences.setProperty("report.dtp.publish.src", "full");
        when(context.getPreferences()).thenReturn(preferences);

        JavascriptSourcesReporterServiceFactory factory = new JavascriptSourcesReporterServiceFactory();
        IResultReporterService service = factory.getServiceUnsafe(context);

        try {
            assertTrue(((JavascriptSourcesReporterServiceFactory.JavascriptSourcesReporterService) service).isEnabled());
        } finally {
            factory.disposeService(context);
        }
    }
}
