---
status: READY
status_reason: "The settings-file format, supported fields, precedence, validation reuse, and recoverable invalid-file behavior have been confirmed."
open_questions_count: 0
source_issue_key: JSC-72
---

# Spec Draft: JSC-72

## Source

- Issue Key: JSC-72
- Title: 3. Support agent configuration through configuration file
- Description:
  - Read the value of `jscov.agent.settings`.
  - Command-line parameters have higher priority than corresponding configurations in the configuration file.
  - The configuration file is JSONC and supports these related configurations:
    - `jscov.agent.runtimeData`
    - `jscov.agent.session.autostart`
    - `jscov.agent.restServerEnabled`
    - `jscov.agent.restServerPort`
    - `jscov.agent.debug`
    - `jscov.agent.silentMode`
    - `jscov.agent.include` and `jscov.agent.exclude` are out of scope.
  - Reuse the existing DTO for parameter configurations and the existing parameter-validation logic.

## Goal

Read supported agent configuration from the JSONC file selected by `jscov.agent.settings`, while preserving command-line precedence and existing configuration validation.

## In Scope

- Read the `jscov.agent.settings` value.
- Parse JSONC configuration files, including comments.
- Supply the supported settings-file values for `runtimeData`, `session.autostart`, `restServerEnabled`, `restServerPort`, `debug`, and `silentMode` through the existing parameter-configuration DTO.
- Give command-line parameters higher priority than corresponding settings-file values.
- Reuse the existing parameter-validation logic.

## Out of Scope

- `jscov.agent.include`.
- `jscov.agent.exclude`.

## Behavior

- When `jscov.agent.settings` identifies a settings file, the agent reads its JSONC content.
- JSONC comments in the settings file are accepted.
- The six related configuration keys in the issue may provide agent configuration values.
- For each corresponding option, a command-line value overrides the value read from the configuration file.
- Settings-file values use the existing DTO and parameter-validation logic rather than a separate representation or validator.
- The agent validates the command-line `settings` path, reads the file, and parses it before resolving the final configuration. (inferred)
- A missing, unreadable, non-file, or malformed JSONC settings file is reported as an error to standard error. The Agent does not start, and the target Node process continues running.

## Design Decisions

- Add a configuration-module reader that returns the existing `AgentConfigInput` DTO containing only the six supported settings-file values.
- Use `jsonc-parser@3.3.1` as a direct, MIT-licensed runtime dependency to parse JSONC. It is the VS Code JSONC parser, accepts comments and trailing commas, and matches the JSONC semantics precisely without accepting broader JSON5 syntax.
- The Agent passes the parsed command-line input as `ARGS` and the settings-file DTO as `SETTINGS_FILE` to the existing resolver; it does not add a separate precedence or validation path.
- A configuration file cannot select itself; `jscov.agent.settings` remains a command-line bootstrap value.
- A missing, unreadable, non-file, or malformed settings file is a fatal configuration error: the Agent logs it to standard error with an `ERROR` level and does not start. The target Node process continues running.

## Edge Cases

- A settings file may contain comments, which must not prevent parsing. (inferred)
- A command-line value and a settings-file value may both be present for the same configuration; the command-line value wins.
- A settings file may be missing, unreadable, a non-file path, or malformed; the Agent logs an error and does not start, while the target Node process continues running.

## Done When (Acceptance Criteria)

- [ ] The agent reads the file identified by `jscov.agent.settings`.
- [ ] A JSONC settings file with comments supplies values for the six listed related configurations.
- [ ] Command-line values take precedence over corresponding settings-file values.
- [ ] The implementation reuses the existing configuration DTO and validation logic.
- [ ] A missing, unreadable, non-file, or malformed JSONC settings file logs an `ERROR` to standard error, prevents Agent-server startup, and leaves the target Node process running.
- [ ] `jscov.agent.include` and `jscov.agent.exclude` are not implemented.

## Clarifications

### Assumptions

- [A1] The settings-file value is an explicit path to the JSONC file to read. This follows the key name and the request to read its value. **Resolved:** the CLI `jscov.agent.settings` value is the bootstrap path; settings-file content does not provide this field.

### Unclear Points

- [U1] The issue does not define the diagnostic or startup behavior when the selected file cannot be read or its JSONC is malformed. **Resolved:** report an `ERROR` to standard error and do not start the Agent server. The target Node process continues running.

### Missing Info

- None identified for the requested configuration fields, precedence, exclusions, DTO reuse, or validation reuse.

### Questions for Human

- [Q1] (re [U1]) If the selected settings file is unreadable or contains malformed JSONC, should the agent report the error and continue without starting the agent server, or report the error and continue with command-line/default values? **Answered:** report an `ERROR` to standard error and do not start the Agent server. The target Node process continues running.

### Risks

- [R1] (re [U1]) Without defined malformed-file behavior, implementations can either conceal an invalid configuration or prevent an expected agent-server startup. **Mitigated:** a visible standard-error `ERROR` stops the Agent server from starting with potentially incorrect configuration, while the target Node process continues running.
