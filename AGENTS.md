# Repository Instructions

## Rule Routing

- Before running commands, proposing an implementation or test plan, reviewing changes, or modifying code, read `AGENTS.index.md`, identify the applicable scopes, and read their mapped `AGENTS.md` files.
- If a request conflicts with a repository rule, explain the conflict and cite the rule file, heading, and relevant bullet before proposing a compliant alternative.

## Project Commands

- Run Gradle tasks through the repository-root Gradle wrapper.

## Tests

- Use i18n resources for all message expectations; add per-locale route tests only for locale-dependent behavior.

## Localization

- All messages(CLI output, log messages, exception messages) must be managed through i18n resource files to avoid hardcoded strings.
- When changing an i18n message, update every supported locale with equivalent meaning and consistent terminology.
- When generating or editing any i18n message (e.g., `.properties` or `.json` values), phrase it the way a native speaker would; grammatically correct but awkward phrasing is not acceptable. Apply this to English and Chinese, the currently supported languages.

## API Contracts

- When an API uses an HTTP status outside its usual semantics, record the required contract rationale in its specification.

## Jenkins Pipelines

- For version-controlled Jenkins pipelines, document externally configured inputs in the file header.
- Use `params.*` only for job controls or inputs needed before environment injection; use `env.*` for environment-specific integration values, including DTP settings and session tags.
- Do not declare Jenkins job parameters in the Jenkinsfile when the job configuration owns them.
- Bind passwords and other secret values with `withCredentials` only in the stage where they are consumed; document the credential ID in the file header instead of secret variables.

## Repository Knowledge

- When a task may need repository structural facts or domain details, read `ARCHITECTURE.md` first. It is the lightweight entry point that routes current behavior to `docs/domain/` and accepted future direction to `docs/design/`; from there, conditionally load only the specific documents the task needs.

## Audit

- For routed work, append the `AGENTS.index.md` and scoped `AGENTS.md` files read, with their applicable scopes, to the end of the final response.
- For routed work, append each read `ARCHITECTURE.md` or Markdown file under `docs/domain/` or `docs/design/`, with the reason it was read, to the end of the final response.

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
