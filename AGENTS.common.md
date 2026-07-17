# Common Agent Rules
> NOTICE: This file is NOT an entry-point policy file and must be loaded through the root `AGENTS.md` resolution flow.

## Model Behavioral Contract
> Precedence: This section has the highest priority. Scoped AGENTS rules may add stricter constraints, but MUST NOT contradict these rules.

### Rule 1 — Think Before Coding
State assumptions explicitly. If uncertain, ask rather than guess.
Present multiple interpretations when ambiguity exists.
Push back when a simpler approach exists.

### Rule 2 — Simplicity First
Minimum code that solves the problem. Nothing speculative.
No features beyond what was asked. No abstractions for single-use code.

### Rule 3 — Surgical Changes
Touch only what you must. Clean up only your own mess.
Don't "improve" adjacent code, comments, or formatting.
Match existing style.

### Rule 4 — Goal-Driven Execution
Define success criteria. Loop until verified.
Don't follow steps—define success and iterate.

### Rule 5 — Use the model only for judgment calls
Use the model for: classification, drafting, summarization, extraction.
Do NOT use the model for: routing, retries, deterministic transforms.

### Rule 6 — Surface conflicts, don't average them
If two patterns contradict, pick one (more recent / more tested).
Explain why. Flag the other for cleanup.

### Rule 7 — Read before you write
Before adding code, read exports, immediate callers, shared utilities.

### Rule 8 — Tests verify intent, not just behavior
Tests must encode WHY behavior matters, not just WHAT it does.

### Rule 9 — Checkpoint after every significant step
Summarize what was done, what's verified, what's left.
Don't continue from a state you can't describe back.

### Rule 10 — Match the codebase's conventions
Conformance > taste inside the codebase.
If you think a convention is harmful, surface it—don't fork silently.

### Rule 11 — Fail loud
"Completed" is wrong if anything was skipped silently.
Default to surfacing uncertainty, not hiding it.

## Development Conventions

1. **Prefer Third-Party Libraries**:
   - **When**: A library exists that covers the required functionality
   - **Do**: Use established third-party libraries instead of custom implementations
   - **Do**: Use latest compatible versions
   - **Do**: Verify permissive licenses (MIT, Apache 2.0, BSD, ISC)
   - **Don't**: Adopt copyleft licenses (GPL, LGPL, AGPL) without approval
   - **Why**: Reduces maintenance burden and avoids license compliance risk

2. **Test Comments**:
   - **When**: Writing or updating unit/integration test files
   - **Do**: Only add section comments (e.g., `// --- loading state ---`) when needed
   - **Don't**: Use numbered prefixes like `1.`, `2.`, `2b.`
   - **Why**: Keeps tests concise and avoids renumbering churn
