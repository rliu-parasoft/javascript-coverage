import { parseCommandLine, resolveConfiguration, type AgentConfig } from './configuration/config.js';
import { startAgent, type StartedAgent } from './server/server.js';

const config = resolveAgentConfiguration();
if (config) {
    await startAgentWithLifecycle(config);
}

function resolveAgentConfiguration(): AgentConfig | undefined {
    try {
        const commandLine = parseCommandLine(process.argv.slice(2));
        process.argv.splice(2, process.argv.length - 2, ...commandLine.targetArgs);
        const resolution = resolveConfiguration([{ source: 'ARGS', input: commandLine.input }]);
        resolution.diagnostics.forEach(logDebug);
        if (resolution.error) {
            logError(resolution.error);
            return undefined;
        }
        if (resolution.config) {
            logIfDebug(resolution.config, `Parasoft JavaScript runtime coverage agent configuration: ${JSON.stringify({ ...resolution.config, settings: resolution.config.settings ?? null })}`);
            logIfDebug(resolution.config, `AUT arguments: ${JSON.stringify(process.argv.slice(2))}`);
        }
        return resolution.config;
    } catch (error) {
        logError(errorMessage(error));
        return undefined;
    }
}

async function startAgentWithLifecycle(config: AgentConfig): Promise<void> {
    try {
        registerShutdownHandlers(await startAgent(config), config);
    } catch (error) {
        logStartupFailure(error);
    }
}

function registerShutdownHandlers(agent: StartedAgent, config: AgentConfig): void {
    let isShuttingDown = false;
    const shutdown = () => {
        if (isShuttingDown) {
            return;
        }
        isShuttingDown = true;
        void agent.close()
            .catch((error: unknown) => logIfDebug(config, `Parasoft JavaScript runtime coverage agent shutdown failed: ${errorMessage(error)}`))
            .finally(() => process.exit(0));
    };
    process.once('SIGINT', shutdown);
    process.once('SIGTERM', shutdown);
}

function logStartupFailure(error: unknown): void {
    logError(`Parasoft JavaScript runtime coverage agent startup failed: ${errorMessage(error)}`);
}

function errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
}

function logDebug(message: string): void {
    process.stdout.write(`[JSCOV-AGENT][DEBUG]: ${message}\n`);
}

function logError(message: string): void {
    process.stderr.write(`[JSCOV-AGENT][ERROR]: ${message}\n`);
}

function logIfDebug(config: AgentConfig, message: string): void {
    if (config.debug) {
        logDebug(message);
    }
}
