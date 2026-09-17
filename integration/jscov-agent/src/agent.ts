import { parseCommandLine, readSettingsFile, resolveConfiguration, type AgentConfig } from './configuration/config.js';
import { LoggerProvider } from './logging/logger.js';
import { writeAgentVersionFile } from './agent-info.js';
import i18n from './i18n.js';
import { RestServiceStartupError, SessionAutostartError, startAgent, type StartedAgent } from './server/server.js';
import { DEFAULT_USER_ID } from './session/session-service.js';
import { errorMessage } from './utils.js';

await startPreloadedAgent();

export async function startPreloadedAgent(): Promise<void> {
    const config = resolveAgentConfiguration();
    if (config) {
        await startAgentWithLifecycle(config);
    }
}

function resolveAgentConfiguration(): AgentConfig | undefined {
    let loggerInitialized = false;
    try {
        const commandLine = parseCommandLine(process.argv.slice(2));
        process.argv.splice(2, process.argv.length - 2, ...commandLine.targetArgs);
        const settingsFile = readSettingsFile(commandLine.input.settings);
        if (settingsFile.error) {
            process.stderr.write(`[JSCOV-AGENT][ERROR]: ${settingsFile.error}\n`);
            return undefined;
        }
        const resolution = resolveConfiguration([
            { source: 'ARGS', input: commandLine.input },
            { source: 'SETTINGS_FILE', input: settingsFile.input }
        ]);

        if (resolution.error) {
            process.stderr.write(`[JSCOV-AGENT][ERROR]: ${resolution.error}\n`);
            return undefined;
        }
        if (resolution.config) {
            LoggerProvider.initialize(resolution.config);
            loggerInitialized = true;
            writeAgentVersionFile(resolution.config.runtimeData);
            LoggerProvider.writeBanner();
            resolution.diagnostics.forEach((message) => LoggerProvider.file.debug(message));
            LoggerProvider.file.debug(
                `Parasoft JavaScript runtime coverage agent configuration: ${JSON.stringify({ ...resolution.config, settings: resolution.config.settings ?? null })}`
            );
            LoggerProvider.file.debug(`AUT arguments: ${JSON.stringify(process.argv.slice(2))}`);
        }
        return resolution.config;
    } catch (error) {
        if (loggerInitialized) {
            const message = errorMessage(error);
            LoggerProvider.file.error(message, error instanceof Error ? error : undefined);
            LoggerProvider.console.error(message);
        } else {
            process.stderr.write(`[JSCOV-AGENT][ERROR]: ${errorMessage(error)}\n`);
        }
        LoggerProvider.close();
        return undefined;
    }
}

async function startAgentWithLifecycle(config: AgentConfig): Promise<void> {
    try {
        registerShutdownHandlers(await startAgent(config));
    } catch (error) {
        if (error instanceof RestServiceStartupError) {
            logRestServiceStartupFailure(error);
        } else if (error instanceof SessionAutostartError) {
            logSessionAutostartFailure(error.underlyingError);
        } else {
            logLifecycleFailure('startup', error);
        }
        await LoggerProvider.close();
    }
}

function logSessionAutostartFailure(error: unknown): void {
    const baseMessage = i18n.t('session_start_failed', {
        userId: DEFAULT_USER_ID
    });
    const message = `${baseMessage} ${errorMessage(error)}`;
    LoggerProvider.console.error(message);
    if (error instanceof Error) {
        LoggerProvider.file.error(baseMessage, error);
    } else {
        LoggerProvider.file.error(message);
    }
}

function logRestServiceStartupFailure(error: RestServiceStartupError): void {
    LoggerProvider.console.error(error.message);
    if (error.underlyingError instanceof Error) {
        LoggerProvider.file.error(error.message, error.underlyingError);
    } else {
        LoggerProvider.file.error(error.message);
    }
}

function registerShutdownHandlers(agent: StartedAgent): void {
    let isShuttingDown = false;
    const shutdown = () => {
        if (isShuttingDown) {
            return;
        }
        isShuttingDown = true;
        void agent.close()
            .catch((error: unknown) => logLifecycleFailure('shutdown', error))
            .finally(() => {
                void LoggerProvider.close().finally(() => process.exit(0));
            });
    };
    process.once('SIGINT', shutdown);
    process.once('SIGTERM', shutdown);
}

function logLifecycleFailure(phase: 'startup' | 'shutdown', error: unknown): void {
    const baseMessage = i18n.t(`agent_${phase}_failed`);
    const message = `${baseMessage}${errorMessage(error)}`;
    LoggerProvider.console.error(message);
    if (error instanceof Error) {
        LoggerProvider.file.error(baseMessage, error);
    } else {
        LoggerProvider.file.error(message);
    }
}
