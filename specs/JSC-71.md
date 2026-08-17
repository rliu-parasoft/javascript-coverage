---
status: READY
status_reason: "JSC-71 parses command-line configuration, resolves source-aware values, validates the effective configuration, and leaves settings-file reading to JSC-72."
open_questions_count: 0
source_issue_key: JSC-71
---

# Spec Draft: JSC-71

## Source

- Issue Key: JSC-71
- Title: 2. Support command line argument passing
- Supported parameters:
  - `jscov.agent.settings`: optional settings-file path; no default.
  - `jscov.agent.runtimeData`: runtime coverage-data directory; no default.
  - `jscov.agent.session.autostart`: optional; default `true`.
  - `jscov.agent.restServerEnabled`: optional; default `true`.
  - `jscov.agent.restServerPort`: optional; default `8050`.
  - `jscov.agent.debug`: optional; default `false`.
- `jscov.agent.include` and `jscov.agent.exclude` are out of scope.

## Goal

Parse agent command-line options, preserve their source and raw values until resolution, and provide reusable validation for the later settings-file integration.

## In Scope

- Parse and strip supported `jscov.agent.*` options from target arguments.
- Represent raw agent inputs and resolved configuration with DTOs.
- Resolve effective values with `ARGS` taking precedence over `SETTINGS_FILE`.
- Validate effective required values and apply optional defaults.
- Emit source-aware diagnostics when effective debug mode is enabled.

## Out of Scope

- Reading or parsing a settings file; this is JSC-72.
- `jscov.agent.include` and `jscov.agent.exclude`.

## Behavior

- The agent is loaded before the target application with Node's `--import` mechanism. When a resolved configuration starts an agent server, startup completes or logs its failure before the target application begins.
- The preload parser accepts both `--key value` and `--key=value` forms. A bare supported boolean option means `true`.
- Recognized agent configurations are removed from `process.argv`; unrelated arguments remain available to the target application. The parser does not treat `--` as a forwarding separator.
- `resolveConfiguration()` accepts one or more source-tagged inputs. For every field, it selects the CLI (`ARGS`) value when specified; otherwise it selects the settings-file (`SETTINGS_FILE`) value when supplied; otherwise it uses the field default if one exists.
- Source selection occurs before validation. Consequently, an invalid CLI optional value overrides a valid settings-file value and falls back to its documented default rather than using the settings-file value.
- The current preload supplies only an `ARGS` input. JSC-72 will read the settings file and supply the `SETTINGS_FILE` input to the same resolver.
- An explicitly supplied `settings` path must exist and be a file. Omitting `settings` is valid and resolves to `undefined`.
- `runtimeData` has no default. The selected effective value must be a non-empty path to a directory, or a path whose directory can be created. A missing, non-directory, or uncreatable value prevents the agent server from starting while the target application continues.
- `sessionAutostart`, `restServerEnabled`, and `debug` accept only booleans or the strings `true` and `false`; other selected values use their defaults.
- `restServerPort` accepts any finite numeric value, including negative, fractional, zero, and out-of-range values. Non-numeric, empty, `NaN`, and infinite values use the default `8050`.
- If the agent server fails to start, the agent logs the error and does not start its server, but the target application continues.
- Debug messages are emitted only when the effective `debug` value is `true`. They are written to stdout; for each selected parameter they use the form `[JSCOV-AGENT][DEBUG]: Agent parameter: <field>=<value> (ARGS|SETTINGS_FILE)`. They also report the final AUT argument list as `[JSCOV-AGENT][DEBUG]: AUT arguments: <JSON array>`.
- Invalid selected optional values log a debug message that states the default used. Required `settings` and `runtimeData` validation errors always use `[JSCOV-AGENT][ERROR]` and are written to stderr.
- Agent-server startup failures use `[JSCOV-AGENT][ERROR]: Parasoft JavaScript runtime coverage agent startup failed: <message>` and are written to stderr. Shutdown failures use `[JSCOV-AGENT][DEBUG]: Parasoft JavaScript runtime coverage agent shutdown failed: <message>` when debug logging is enabled.

## Required-Value Errors

- `Value of 'settings' configuration should point to file but points incorrectly to directory: <value>`
- `Agent settings file does not exist: <value>`
- `Agent runtime data directory was not set - parameter "jscov.agent.runtimeData" is missing!`
- `Agent runtime data directory: <value> cannot be created.`
- `Agent runtime data configuration is not a directory: <value>`

## Design Decisions

- `AgentConfigInput` retains unvalidated values. `AgentConfig` contains only resolved values.
- `ConfigurationInput` pairs each input with `ARGS` or `SETTINGS_FILE`; `ConfigurationResolution` returns the resolved configuration, debug diagnostics, or an error message.
- Validation occurs in the source-aware resolver rather than during command-line parsing, so JSC-72 can reuse exactly the same precedence, defaults, validation, and diagnostics.
- The settings-file path is a bootstrap value: JSC-72 must validate and read it before supplying settings-file values to the resolver.
- `yargs-parser` handles command-line syntax; the agent owns application-specific defaults, precedence, filesystem validation, and diagnostics.

## Edge Cases

- Repeated options use the final supplied value.
- A bare boolean and an explicit boolean assignment follow their command-line order; the final form wins.
- A selected empty `runtimeData` value is treated as missing.
- A debug-disabled configuration still reports required-value errors, but emits no debug diagnostics.

## Done When

- [x] All supported CLI parameters are parsed and represented by DTOs.
- [x] Recognized agent options are absent from the target application's arguments.
- [x] Source-aware resolution supports `ARGS` and `SETTINGS_FILE` inputs, with CLI precedence.
- [x] Required effective values are validated and prevent only agent-server startup on error.
- [x] Optional defaults and finite-number port handling match the documented behavior.
- [x] Debug diagnostics are gated by effective debug mode and identify their source.
- [x] JSC-71 does not read a settings file.

## Clarifications

### Assumptions

- [A1] Agent-specific options are consumed by the preload rather than forwarded to the target application. **Resolved:** recognized options and their values are removed from `process.argv`.
- [A2] A supplied CLI value has precedence even when invalid. **Resolved:** it is selected before validation; optional fields then use defaults, while required fields report an error.

### Unclear Points

- None blocking JSC-71.

### Missing Info

- None for JSC-71. JSC-72 owns the settings-file format and parsing.

### Questions for Human

- [Q1] Should settings-file reading be implemented in JSC-71? **Answered:** No; JSC-72 supplies the `SETTINGS_FILE` input to the shared resolver.

### Risks

- [R1] A numeric port that Node cannot bind can still fail during server startup. **Mitigated:** preserve the selected finite numeric value and let server startup report its own failure.
- [R2] Incorrectly applying settings-file values before CLI values would hide explicit user input. **Mitigated:** source selection is fixed as `ARGS`, then `SETTINGS_FILE`, then default.
