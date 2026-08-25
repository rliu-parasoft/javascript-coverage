---
status: READY
status_reason: "The user resolved the only unspecified REST error-contract detail."
open_questions_count: 0
source_issue_key: JSC-77
---

# Spec: JSC-77

## Source

- Issue Key: JSC-77
- Title: 3. Add GET/POST - /session/start REST APIs
- Description (fetched from Jira):

  - Support both GET and POST methods.
  - Record the current session id in memory. The format is:
    - `runtime_coverage_${timestamp}_${sequenceNumber}`
    - Store in Map format, key is userId, value is sessionId
    - The current default userId is `__default__`
  - Clear the hit information of `__coverage__` in the node process.
  - Create a `__default__/${sessionId}.json` file to prepare for storing coverage data.
    - `__default__` is the default user id.
    - The file is located under the runtimeData folder.
  - Normal
    - Status code: 200
    - Body

      ```json
      {
          "session": "runtime_coverage_8b39_20260807_1603_0"
      }
      ```

  - A session is already in active status and cannot be started repeatedly.
    - Status code: 400
    - Body

      ```json
      {
          "messageCode": 150,
          "message": "Session is already started"
      }
      ```

  - Internal server error
    - Status code: 500
    - Body

      ```json
      {
          "messageCode": ${code},
          "message": "xxxx"
      }
      ```

### User-provided corrections and additions

- The sample session value in the Jira description is superseded by the required format `runtime_coverage_${timestamp}_${sequenceNumber}`.
- `timestamp` uses GregorianCalendar semantics in `yyyyMMdd_HHmm` format.
- Start the sequence number at `0`; if that file already exists, increment and retry until the generated path is unused.
- The session-start operation must be reusable by JSC-75 session autostart.
- Stopping and restarting the agent permits a new session; existing session JSON files remain.
- The route structure must accommodate later `/session/stop`, `GET /coverage/{sessionId}`, `DELETE /coverage/{sessionId}`, and other REST APIs.
- Session-ID generation must be safe when concurrent starts target the same user and timestamp.
- Concurrent starts for the same user must create at most one session; currently this applies to `__default__`.
- Create each session file with valid initial JSON content.
- Add diagnostics for session-start outcomes without exposing coverage content.
- ~~When debug logging is enabled, log the runtime hit counters before and after the session-start reset.~~
- Inspect runtime hit information before and after session start through the VS Code debugger instead of logging coverage snapshots.
- Reset only the currently supported Istanbul hit counters (`s`, `f`, and `b`); leave `bT` unchanged until its semantics are understood.

### Parent story source

- Issue Key: JSC-52
- Title: REST server in Node process to collect/reset runtime coverage
- Description (fetched from Jira):

  As a user, I want a *lightweight HTTP server* to start automatically inside my running (instrumented) Node.js backend process, so that I can *query and reset the current overall runtime coverage* via REST calls.

  The agent should be preloaded into the user's Node process and able to read the global coverage object the instrumented code writes to. This story delivers only get and reset on the overall coverage of the whole process.

  We should reference the Jtest coverage agent's behavior (its agent.properties, port configuration?, and endpoints) where applicable.

  *Acceptance criteria*

  - Preloading the agent into an instrumented CJS backend process (via `node --require <agent>`, or a `package.json` script) brings up the HTTP server on a configurable port, with a `/status` endpoint to confirm the agent is attached (referencing Jtest agent).
  - The server exposes API to get and reset the overall coverage of the whole process, with behavior consistent with the Jtest coverage agent.
  - When the API is called after the Node process has started and the agent is loaded, but before any application code has run (so the instrumented global coverage object has not yet been created), the API returns gracefully instead of erroring.

  *Out of scope*

  - ESM: preloading under ESM appears to only require swapping the flag `--require` to `--import`; but if other complications surface, we'll decide case-by-case whether to handle them in this story.
  - XML conversion and DTP upload.
  - Automatic dump a runtime coverage JSON on process exit.
  - Frontend runtime collection.

### Story corrections supplied by the user

- Preloading the agent into an instrumented CJS backend process uses `node --import <agent>` or a `package.json` script.
- The agent provides a configurable-port HTTP server and `/status` endpoint.
- JSC-77 adds session-start behavior to the runtime-coverage REST capability; later tasks add session stop and coverage retrieval/deletion endpoints.
- The loaded agent must handle an absent global coverage object gracefully before application code runs.

## Goal

Add GET and POST `/session/start` APIs that start one default-user runtime coverage session, reset the Node process's Istanbul hit data, and reserve an empty session JSON file under the configured runtime data directory.

## Design Decision

- Use a focused reusable session service rather than placing session state and filesystem operations in Express route handlers.
- Keep HTTP concerns in the route layer: both verbs call the same service operation and translate its outcome into the documented response body and status.
- The session service owns the in-memory user-to-session map and collision-safe session-file preparation; a focused runtime-coverage module owns process-global hit reset.
- Keep the runtime-coverage reset function independently reusable by later coverage APIs without introducing a class or new dependency.
- Before preparation, it reserves the user as starting. A request finding that user either starting or active returns the standard HTTP 400/150 response without resetting coverage or creating a file. The temporary reservation is released only when preparation fails; it becomes the active-map entry on success.
- It reserves each candidate JSON path with Node's exclusive-create mode (`wx`); an `EEXIST` error increments the sequence number and retries. This makes the persisted file the concurrency-safe session-ID reservation.
- Use Node's local `Date` calendar fields to produce the required Gregorian-calendar `yyyyMMdd_HHmm` timestamp; no new dependency is required.
- Reserve each session file with the valid JSON document `{}` rather than an empty file.
- Emit successful and duplicate-start diagnostics only when agent debug logging is enabled; emit unexpected preparation failures as agent errors before sending their HTTP 500 response.
- Reset the supported Istanbul hit counters (`s`, `f`, and `b`) without logging coverage snapshots; leave `bT` unchanged until a later task defines its semantics.
- When a reset fails after file reservation, clean up the reservation on a best-effort basis without masking the reset failure that determines the HTTP 500 response.
- Cover the reset through a preloaded child process with live instrumented-style coverage data, in addition to service-level tests.
- Use OS-assigned ports in preload tests and derive the test request URL from the agent's startup output, avoiding fixed-port interference.
- If reservation cleanup fails, emit a debug diagnostic for that cleanup failure without changing the original preparation error returned by the REST route.

## In Scope

- Register both GET and POST `/session/start` on the existing agent REST server.
- Maintain in-memory active-session state in a `Map<string, string>` from user ID to session ID, initially using only `__default__`.
- Generate collision-free session IDs from the local Gregorian-calendar timestamp and sequence number.
- Clear the process global `__coverage__` hit counters without failing when instrumentation has not created it. (inferred)
- Create the empty `runtimeData/__default__/${sessionId}.json` file before reporting the successful session. (inferred)
- Initialize `runtimeData/__default__/${sessionId}.json` as valid JSON before reporting the successful session.
- Structure the session-start operation as reusable service logic for future autostart and session/coverage APIs. (inferred)
- Add behavior-focused tests for HTTP verbs, success, duplicate starts, session-name collisions, coverage reset, persistence preparation, and internal failures. (inferred)
- Add a preload-process regression test proving `/session/start` clears the supported live `globalThis.__coverage__` counters (`s`, `f`, and `b`) while leaving `bT` unchanged. (inferred)
- Verify that duplicate starts leave every existing `__coverage__` hit counter unchanged. (inferred)
- Keep runtime-coverage reset logic separate from session lifecycle and filesystem reservation logic. (inferred)

## Out of Scope

- XML conversion and DTP upload.
- Automatically dumping a runtime coverage JSON file when the process exits.
- Frontend runtime collection.
- Implementing session stop or coverage retrieval/deletion endpoints.
- ESM-specific preload work beyond the existing agent startup behavior.

## Behavior

- GET and POST `/session/start` invoke the same default-user session-start operation.
- If no session is active for `__default__`, the operation selects the first unused `runtimeData/__default__/runtime_coverage_yyyyMMdd_HHmm_N.json` path, starting at `N = 0`.
- The server clears supported execution-hit information (`s`, `f`, and `b`) from the process coverage global before data collection begins; `bT` remains unchanged until its semantics are defined. An absent coverage global is treated as an empty, valid coverage state. (inferred)
- The server creates the default-user directory and an empty JSON file, records the selected session as active, and responds with HTTP 200 and `{ "session": "<sessionId>" }`.
- The reserved JSON file initially contains `{}` and is parseable before any later coverage data is written.
- A second start while the default-user session is active makes no reset or file changes and responds with HTTP 400 and the localized message `Session '<sessionId>' is already started for user '__default__'` with message code `150`.
- A duplicate start preserves all existing process hit counters (`s`, `f`, `b`, and `bT`) as well as session/file state. (inferred)
- A concurrent start while the default-user session is still being prepared follows the same HTTP 400/150 contract and cannot create a second session file. (inferred)
- A failure while preparing a new session responds with HTTP 500 and `{ "messageCode": 500, "message": "<error message>" }`; it must not leave the session marked active. (inferred)
- If cleanup of a reserved file also fails during preparation failure, the original preparation error remains the HTTP 500 message. (inferred)
- With agent debug enabled, a failed reservation cleanup emits a diagnostic but does not replace the original preparation error. (inferred)
- With agent debug enabled, the agent logs successful and duplicate session-start outcomes. Unexpected session-start preparation errors are logged as errors before the HTTP 500 response. (inferred)
- Session-start responses, validation errors, and diagnostics use the JSC-109 localization resources for the agent locale; the original English text remains the English fallback. (inferred)
- Operators inspect `__coverage__` before and after session start in the VS Code debugger; session start does not log coverage snapshots. (inferred)
- Agent restart creates fresh in-memory state; existing runtime-data files remain available for collision detection.

## Edge Cases (Optional)

- The timestamp repeats within a minute or persisted files from a previous agent process use the same timestamp; sequence allocation skips all occupied names.
- Concurrent starts for different users or agent processes can select the same candidate name; exactly one exclusive file creation succeeds, and every loser retries with the next sequence number.
- Concurrent starts for the same user are serialized by the in-memory user reservation; only one is allowed to prepare a session.
- The process is loaded before any instrumented application code; no `__coverage__` property exists yet.
- The runtime-data path becomes unwritable or file creation fails; no active session is recorded.
- The reserved session file is externally removed before failure cleanup; the original reset failure is still reported.
- A preload test runs while another process may hold the default port; it receives an OS-assigned port instead of relying on a fixed listener.

## Done When (Acceptance Criteria)

- [x] Both GET and POST `/session/start` return 200 with a generated session ID when no default-user session is active.
- [x] A successful start resets process coverage hits, creates the expected empty JSON file, and records `__default__` to its session ID.
- [x] Session IDs use `runtime_coverage_yyyyMMdd_HHmm_N`, allocate `N` from zero, and avoid persisted-file collisions.
- [x] Concurrent session starts never return the same session ID; all returned IDs have uniquely reserved JSON files.
- [x] Concurrent starts for `__default__` produce one successful session start at most; every competing request returns the specified 400 duplicate-session response without side effects.
- [x] Repeated starts return the specified HTTP 400 duplicate-session response without mutating state.
- [x] Preparation failures return HTTP 500 without leaving an active session. (inferred)
- [x] Session-start logic can be reused independently of the HTTP route by autostart work. (inferred)
- [x] Existing server and preload behavior remain covered by the module test suite. (inferred)
- [x] New session files contain valid JSON, and the agent logs session-start outcomes according to its debug/error logging policy. (inferred)
- [x] Session start resets only the supported runtime hit counter groups (`s`, `f`, and `b`) and leaves `bT` unchanged until its semantics are defined. (inferred)
- [x] A preloaded process test verifies `/session/start` clears supported live `globalThis.__coverage__` hit counters while leaving `bT` unchanged. (inferred)
- [x] Reservation cleanup is best effort and cannot mask the preparation error reported to the REST caller. (inferred)
- [x] Preload tests use their agent's OS-assigned port rather than a fixed port. (inferred)
- [x] Cleanup failures produce a debug diagnostic while preserving the original preparation error. (inferred)
- [x] Session-start messages are localized through the shared agent localization resources. (inferred)
- [x] Duplicate starts are verified to preserve all existing coverage hit counters. (inferred)
- [x] The README documents how to inspect `__coverage__` before and after session start with the VS Code debugger, without producing coverage snapshot logs. (inferred)
- [x] Runtime-coverage reset is reusable independently of `SessionService` while all session-start behavior remains unchanged. (inferred)

## Clarifications

### Assumptions

- [A1] `__coverage__` follows the Istanbul coverage object shape and clearing its statement, function, and branch hit values is the required reset behavior.

### Unclear Points

- [U1] The required `messageCode` for HTTP 500 is written as `${code}`; no code or mapping is supplied. → **Resolved:** use message code `500`.

### Missing Info

- [M1] No 500 message wording is prescribed beyond the placeholder `xxxx`; the implementation should expose the underlying error message unless a project error-catalog convention is provided. → **Resolved:** use the thrown error's message.

### Questions for Human

- [Q1] (re [U1], [M1]) What `messageCode` and message policy should `/session/start` use for an internal failure? I recommend code `500` and the thrown error's message, which preserves diagnosability without introducing an unprovided error catalog. → **Answered:** use the recommendation.

### Risks

- [R1] (re [U1]) Selecting a different 500 code later would change the externally observable REST contract and require client/test updates.
