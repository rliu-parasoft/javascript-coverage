# Repository Instructions

## Rule Routing

- Before running commands, proposing an implementation or test plan, reviewing changes, or modifying code, read `AGENTS.index.md`, identify the applicable scopes, and read their mapped `AGENTS.md` files.
- If a request conflicts with a repository rule, explain the conflict and cite the rule file, heading, and relevant bullet before proposing a compliant alternative.

## Project Commands

- Run Gradle tasks through the repository-root Gradle wrapper.

## Audit

- For routed work, append the `AGENTS.index.md` and scoped `AGENTS.md` files read, with their applicable scopes, to the end of the final response.

## Cross-Project Engineering Rules

### Dependencies

**When:** A task evaluates, recommends, or adds a new direct dependency.

**Do:**
- Reuse an existing project dependency when it satisfies the requirement.
- Otherwise, evaluate an appropriate third-party dependency before a new custom implementation.
- Before recommending or adding a dependency, check its license.
- Reject GPL, LGPL, and AGPL dependencies.
- For other copyleft or unknown licenses, ask the user before recommending or adding the dependency.
- For an approved dependency, select a current stable version compatible with the project's runtime and build tooling.

**Don't:**
- Add a dependency for small, single-use functionality that is simpler and safer to maintain locally.
- Upgrade unrelated existing dependencies solely to use their latest versions.
