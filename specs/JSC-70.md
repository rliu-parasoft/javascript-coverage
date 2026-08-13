---
status: READY
status_reason: "The project structure, runtime module boundary, default port, error behavior, temporary health endpoint, distribution content, and verification strategy have been reviewed and approved."
open_questions_count: 0
source_issue_key: JSC-70
---

# Spec Draft: JSC-70

## Source
- Issue Key: JSC-70
- Title: 1. Create project skeleton
- Description:
  - Module: `/integration/jscov-agent`.
  - Create a TypeScript + Vite project using Express.
  - Swagger is not considered at this stage.
  - The default agent port is `8050`.
  - Start the agent and application under test with `node --import ./agent.js uta-server.js`.
  - When the tested server starts, output placeholder logs indicating that the agent server has started on default port `8050`.
  - Check whether the port is occupied using Node.js facilities; no custom implementation is required.
  - Build output in `/integration/jscov-agent` includes `agent.js` and `agent.jsonc`. JSONC is used because it supports comments.

## Goal
Create `/integration/jscov-agent` as an Express-based TypeScript agent that can be preloaded with Node's ESM import hook, waits for its server to listen before the application under test starts, uses port `8050` by default, and is packaged with its JSONC configuration.

## In Scope
- Add `/integration/jscov-agent` as a Gradle integration subproject.
- Use Vite to bundle the TypeScript preload entry point as an ESM `agent.js`.
- Start the agent with `node --import ./agent.js uta-server.js` so top-level `await` completes before Node evaluates the application-under-test entry point; CommonJS UTAs remain supported.
- Use Express for the agent server.
- Read default port `8050` from `agent.jsonc`.
- Precheck port availability synchronously with Node.js capabilities before starting the Express server, so a known occupied port stops the preload before the application-under-test entry point executes.
- Fail the preload path when configuration is invalid, the port is unavailable, or Express fails to listen.
- Emit a startup placeholder log identifying the agent server and default port `8050`.
- Provide a temporary `GET /health` endpoint for manual testing only; it is not a stable API.
- Keep the module build output limited to `agent.js` and `agent.jsonc`.
- Add unit and preload-integration verification for the skeleton.

## Out of Scope
- Swagger support.
- Command-line and configuration-file port override behavior beyond the current default configuration.
- UTA module-system support beyond CommonJS and standard ESM entry points.
- A stable or documented public HTTP API; `GET /health` is temporary manual-test support only.
- Gradle staging, root zip packaging, and generated runtime `package.json` metadata.

## Design

### Components
- `src/agent.ts` is the ESM preload entry point. It reads the configuration, validates and prechecks the port, then awaits the Express server startup.
- `agent.jsonc` contains the current port setting: `8050`.
- A small health-route module exposes temporary `GET /health` and returns HTTP 200. Its source and documentation label it as temporary and for manual testing.
- `vite.config.ts` produces the `agent.js` preload artifact required by Jira.
- The build directory contains exactly `agent.js` and `agent.jsonc`.

### Startup Flow
1. Node preloads `agent.js` using `node --import ./agent.js uta-server.js`.
2. The agent reads `agent.jsonc` and obtains port `8050`.
3. The agent validates the port and synchronously checks whether it is already occupied using a short-lived Node.js child process.
4. If validation and the port check succeed, the agent starts Express and logs that it has started on port `8050`.
5. Only after the top-level startup await completes does Node load the application-under-test entry point.

## Behavior
- With no future override applied, the agent reads and uses port `8050` from `agent.jsonc`.
- `node --import ./agent.js uta-server.js` starts and awaits the agent before the application under test, including when the UTA is CommonJS.
- A successful startup emits a placeholder log containing that the agent started and is using port `8050`.
- `GET /health` returns HTTP 200 solely for manual testing during this skeleton stage.
- The build output contains exactly `agent.js` and `agent.jsonc`.

## Error Handling
- Invalid or unreadable configuration writes a clear error to stderr and terminates with a non-zero exit status.
- An invalid port or port already in use writes a clear error to stderr and terminates with a non-zero exit status; the Express server and application under test must not continue.
- An Express listen failure after a successful precheck writes a clear error to stderr and terminates with a non-zero exit status. A small time-of-check/time-of-use race remains between the precheck and listen operation.

## Done When (Acceptance Criteria)
- [ ] `/integration/jscov-agent` exists as a TypeScript, Vite, and Express Gradle integration subproject.
- [ ] Vite produces ESM `agent.js` that can be passed to Node `--import`.
- [ ] The build output includes exactly `agent.js` and `agent.jsonc`.
- [ ] The agent reads default port `8050` from `agent.jsonc`.
- [ ] `node --import ./<agent.js> uta-server.js` waits for the agent before loading the application under test.
- [ ] A port already in use prevents the agent and application under test from continuing, with a clear stderr error and non-zero exit status.
- [ ] Successful startup logs that the agent server started on port `8050`.
- [ ] Temporary `GET /health` returns HTTP 200 and is clearly marked as a manual-test-only endpoint.
- [ ] Swagger is not included.

## Testing
- Unit tests cover configuration loading, port validation, synchronous occupied-port handling, and the temporary health route.
- Manual verification covers `node --import ./agent.js uta-server.js` with a CommonJS UTA.
- Build checks verify that stale generated files are removed and only the required output files remain.

## Clarifications

### Assumptions
- None for this iteration.

### Unclear Points
- None blocking implementation. Jira does not prescribe an exact startup-log message or behavior after a port conflict. → **Resolved:** Use a clear stderr error and non-zero exit status for conflicts; the successful placeholder log must identify the agent server and port `8050`.

### Missing Info
- None for this iteration.

### Questions for Human
- None for this iteration.

### Risks
- [R1] The temporary health endpoint could become an accidental compatibility surface. **Mitigated:** Clearly mark it as manual-test-only in source and documentation.
- [R3] A different process can claim the port after the synchronous precheck but before Express listens. **Mitigated:** Handle the later listen failure with stderr output and a non-zero exit status.
