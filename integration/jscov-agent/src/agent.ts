import { getConfig } from './configuration/config.js';
import { startAgent } from './server/server.js';

const config = getConfig();

const agent = await startAgent(config).catch((error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    process.stderr.write(`Parasoft JavaScript runtime coverage agent startup failed: ${message}\n`);
    process.exit(1);
});

const shutdown = () => void agent.close()
        .catch((error: unknown) => {
            const message = error instanceof Error ? error.message : String(error);
            process.stderr.write(`Parasoft JavaScript runtime coverage agent shutdown failed: ${message}\n`);
        })
        .finally(() => process.exit(0));
process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);
