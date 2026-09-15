# Runtime Coverage Agent

## Scope

This document defines current, repository-internal behavior of `integration/jscov-agent`: a Node.js agent preloaded into an application-under-test (AUT) process via `node --import` to collect and reset **runtime execution** coverage, distinct from the static-coverage contract in [Static Coverage Contract](static-coverage-contract.md). The authoritative REST contract — routes, methods, status codes, and schemas — is [`integration/jscov-agent/openapi.yml`](../../integration/jscov-agent/openapi.yml); this document does not restate it and defers to it on conflict.

## Session Model

- Single-user only; the sole user id is `__default__`. At most one active session per user.
- A session id has the form `runtime_coverage_yyyyMMdd_HHmm_N`, using the local Gregorian-calendar timestamp and a sequence number starting at `0`. Collisions with existing session files are resolved by incrementing `N` and retrying an exclusive file create.
- Starting a session reserves `runtimeData/__default__/<sessionId>.json`, initialized to `{}`, and resets the process's `__coverage__` hit counters `s`, `f`, and `b` (leaving `bT` unchanged until its semantics are defined). An absent `__coverage__` global is treated as an empty, valid coverage state.
- Starting a session while one is already active for the user makes no reset or file changes and reports a duplicate-session response; it does not create a competing session.
- Stopping a session persists the active session's coverage to its session JSON file through an atomic replace, then clears the active-session record only after that write succeeds. If persistence fails, the existing session JSON file remains valid for retry.
- Before serialization, file coverage entries with an `inputSourceMap` are remapped to their original source locations on a best-effort basis; entries that cannot be mapped retain their generated form rather than blocking the stop.
- Restarting the agent produces fresh in-memory session state; existing session JSON files on disk remain available for collision detection.

## REST Surface

Routes are grouped as Session (`/session/start`, `/session/stop`), Coverage (`/coverage`, `/coverage/{id}`), and Other (`/status`, `/config`, `/info`). Error responses use the shared `{ messageCode, message }` shape with localized text. For exact methods, path parameters, status codes, and response schemas (including the `GET /coverage/{id}` archive's `405` contract when the runtime version manifest is missing), read `openapi.yml` directly rather than relying on a restated summary here.

## Runtime Version Manifest

- At every agent initialization, the agent creates or overwrites `<runtimeData>/version.json` with `{"schemaVersion":"1.0","toolVersion":"<jscov-agent package version>"}`.
- A failure creating or writing this file is non-fatal to the preload: it is recorded in the agent's file log (with stack trace) and reported to the console as a localized message without a stack trace; agent initialization stops without throwing from the preload module.
- This manifest is independent of the static-coverage manifest at `.parasoft/static-coverage/<pid>/version.json` (see [Static Coverage Contract](static-coverage-contract.md)); the two are written by different components for different consumers and must not be conflated.

## Configuration Resolution Contract

- Effective value precedence per field: command-line arguments (`ARGS`) override settings-file values (`SETTINGS_FILE`), which override built-in defaults. Source selection happens before validation.
- An invalid selected optional value falls back to that field's documented default; it does not fall back to a differently-sourced valid value (e.g. an invalid CLI value does not defer to a valid settings-file value).
- Supported fields: `runtimeData` (required; must resolve to an existing or creatable directory, no default), `settings` (CLI-only bootstrap path to a JSONC file; not itself settable from within that file), `sessionAutostart` (default `true`), `restServerEnabled` (default `true`), `restServerPort` (default `8050`; any finite numeric value is accepted, non-finite or non-numeric values fall back to the default), `debug` (default `false`), `silentMode` (default `false`).
- A missing, unreadable, non-file, or malformed JSONC settings file is a fatal configuration error: it is logged at `ERROR` level to standard error, and the agent server does not start; the target Node process continues running unaffected.
- `jscov.agent.include` and `jscov.agent.exclude` are explicitly out of scope for settings-file and command-line configuration.

## Related Components

- Server and routes: `integration/jscov-agent/src/server/`
- Session lifecycle: `integration/jscov-agent/src/session/session-service.ts`
- Configuration resolution: `integration/jscov-agent/src/configuration/config.ts`
- REST contract: `integration/jscov-agent/openapi.yml`
- Behavior evidence: `integration/jscov-agent/test/server/`, `test/session/`, `test/configuration/`; `specs/JSC-71.md`, `JSC-72.md`, `JSC-77.md`, `JSC-112.md`

## Related Documents

- [Architecture Map](../../ARCHITECTURE.md)
- [Current Domain Knowledge](index.md)
- [Static Coverage Contract](static-coverage-contract.md)
