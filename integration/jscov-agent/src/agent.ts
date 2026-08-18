import { parseCommandLine, resolveConfiguration, type AgentConfig } from './configuration/config.js';
import { LoggerProvider } from './logging/logger.js';
import { startAgent, type StartedAgent } from './server/server.js';
import { errorMessage } from './utils.js';

const config = resolveAgentConfiguration();
if (config) {
    await startAgentWithLifecycle(config);
}

function resolveAgentConfiguration(): AgentConfig | undefined {
    try {
        const commandLine = parseCommandLine(process.argv.slice(2));
        process.argv.splice(2, process.argv.length - 2, ...commandLine.targetArgs);
        const resolution = resolveConfiguration([{ source: 'ARGS', input: commandLine.input }]);

        if (resolution.error) {
            process.stderr.write(`[JSCOV-AGENT][ERROR]: ${resolution.error}\n`);
            return undefined;
        }
        if (resolution.config) {
            LoggerProvider.initialize(resolution.config);
            LoggerProvider.writeBanner();
            resolution.diagnostics.forEach((message) => LoggerProvider.file.debug(message));
            LoggerProvider.file.debug(
                `Parasoft JavaScript runtime coverage agent configuration: ${JSON.stringify({ ...resolution.config, settings: resolution.config.settings ?? null })}`
            );
            LoggerProvider.file.debug(`AUT arguments: ${JSON.stringify(process.argv.slice(2))}`);
        }
        return resolution.config;
    } catch (error) {
        process.stderr.write(`[JSCOV-AGENT][ERROR]: ${errorMessage(error)}\n`);
        LoggerProvider.close();
        return undefined;
    }
}

async function startAgentWithLifecycle(config: AgentConfig): Promise<void> {
    try {
        registerShutdownHandlers(await startAgent(config));
    } catch (error) {
        logLifecycleFailure('startup', error);
        await LoggerProvider.close();
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
    const baseMessage = `Parasoft JavaScript runtime coverage agent ${phase} failed: `;
    const message = `${baseMessage}${errorMessage(error)}`;
    LoggerProvider.console.error(message);
    if (error instanceof Error) {
        LoggerProvider.file.error(baseMessage, error);
    } else {
        LoggerProvider.file.error(message);
    }
}
