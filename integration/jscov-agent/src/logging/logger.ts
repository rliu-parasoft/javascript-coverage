import { closeSync, openSync, readdirSync } from 'node:fs';
import { randomInt } from 'node:crypto';
import { join } from 'node:path';
import type { AgentConfig } from '../configuration/config.js';
import i18n from '../i18n.js';
import { createLogger, format, transports, type Logger } from 'winston';

export interface LoggerAdapter {
    debug(message: string): void;
    info(message: string): void;
    warn(message: string): void;
    error(message: string, error?: Error): void;
}

const silentLogger: LoggerAdapter = {
    debug: () => undefined,
    info: () => undefined,
    warn: () => undefined,
    error: () => undefined
};

function reserveAgentLogFile(runtimeData: string): string {
    const nextSequence = Math.max(
        0,
        ...readdirSync(runtimeData)
            .map((file) => /^agent-(\d+)-\d{10}\.log$/.exec(file)?.[1])
            .filter((sequence): sequence is string => sequence !== undefined)
            .map(Number)
    ) + 1;

    while (true) {
        const randomSuffix = randomInt(0, 10_000_000_000).toString().padStart(10, '0');
        const filePath = join(runtimeData, `agent-${nextSequence.toString().padStart(6, '0')}-${randomSuffix}.log`);
        try {
            const fd = openSync(filePath, 'wx');
            closeSync(fd);
            return filePath;
        } catch (error) {
            if ((error as NodeJS.ErrnoException).code !== 'EEXIST') {
                throw error;
            }
        }
    }
}

const consoleFormat = format.printf(({ level, message }) =>
    `[JSCOV-AGENT][${level.toUpperCase()}]: ${String(message)}`
);

const fileFormat = format.combine(
    format.errors({ stack: true }),
    format.timestamp({ format: 'MM-DD HH:mm:ss' }),
    format.printf(({ level, message, stack, timestamp }) => {
        const formattedMessage = `[JSCOV-AGENT][${level.toUpperCase()}][${String(timestamp)}]: ${String(message)}`;
        return stack ? `${formattedMessage}\n${stack}` : formattedMessage;
    })
);

export class LoggerProvider {
    private static instance: LoggerProvider | undefined;
    private readonly fileLogger: Logger;
    private readonly consoleLogger: Logger | undefined;
    private readonly silentMode: boolean;
    private closePromise: Promise<void> | undefined;

    private constructor(config: AgentConfig) {
        this.silentMode = config.silentMode;
        this.fileLogger = createLogger({
            level: config.debug ? 'debug' : 'warn',
            format: fileFormat,
            transports: [new transports.File({ filename: reserveAgentLogFile(config.runtimeData) })]
        });
        this.consoleLogger = config.silentMode
            ? undefined
            : createLogger({
                level: 'info',
                format: consoleFormat,
                transports: [new transports.Console({ stderrLevels: [] })]
            });
    }

    static initialize(config: AgentConfig): void {
        if (LoggerProvider.instance) {
            throw new Error('LoggerProvider has already been initialized.');
        }
        LoggerProvider.instance = new LoggerProvider(config);
    }

    static get file(): LoggerAdapter {
        return LoggerProvider.getInstance().fileLogger;
    }

    static get console(): LoggerAdapter {
        return LoggerProvider.getInstance().consoleLogger ?? silentLogger;
    }

    static writeBanner(): void {
        if (!LoggerProvider.getInstance().silentMode) {
            process.stdout.write(`${i18n.t('agent_initializing')}\n`);
        }
    }

    static close(): Promise<void> {
        return LoggerProvider.instance?.close() ?? Promise.resolve();
    }

    private static getInstance(): LoggerProvider {
        return LoggerProvider.instance ?? throwUnconfiguredLogger();
    }

    private close(): Promise<void> {
        if (!this.closePromise) {
            this.closePromise = closeLoggers([this.fileLogger, this.consoleLogger]).then(() => {
                if (LoggerProvider.instance === this) {
                    LoggerProvider.instance = undefined;
                }
            });
        }
        return this.closePromise;
    }
}

function throwUnconfiguredLogger(): never {
    throw new Error('LoggerProvider has not been configured.');
}

function closeLoggers(loggers: Array<Logger | undefined>): Promise<void> {
    return Promise.all(
        loggers.filter((logger): logger is Logger => logger !== undefined)
            .map((logger) => new Promise<void>((resolve) => {
                let settled = false;
                const settle = () => {
                    if (settled) {
                        return;
                    }
                    settled = true;
                    logger.removeListener('finish', settle);
                    logger.removeListener('error', settle);
                    logger.removeListener('close', settle);
                    resolve();
                };

                logger.once('finish', settle);
                logger.once('error', settle);
                logger.once('close', settle);
                try {
                    logger.end();
                } catch {
                    settle();
                }
            }))
    ).then(() => undefined);
}
