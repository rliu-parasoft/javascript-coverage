const DEFAULT_PORT = 8050;

export interface AgentConfig {
    port: number;
}

export function getConfig(args: string[] = process.argv.slice(2)): AgentConfig {
    void args;
    return { port: DEFAULT_PORT };
}
