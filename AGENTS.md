# Global Agent Rules (Entry Point)

## Entry-Point Contract
- Root `AGENTS.md` MUST be loaded first and applied to all tasks.
- Implementation or code review MUST NOT begin before resolution completes.

## Resolution Process
1. Load root `AGENTS.md`
2. Load `AGENTS.common.md`
3. Load `AGENTS.index.md` and determine scope
4. Load matched scope files from index
5. List all loaded files before starting work
6. If scope expands, reload matched files

## Repository-Specific Rules
- Reserved for root-level rules specific to this repository.
