export type AgentMode = 'singleuser';

export interface AgentDescriptor {
    readonly mode: AgentMode;
    readonly toolId: 'parasoft-jscov';
}

export const currentAgentDescriptor: AgentDescriptor = {
    mode: 'singleuser',
    toolId: 'parasoft-jscov'
};
