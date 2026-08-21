---
status: READY
status_reason: "All three read-only endpoints are implemented; /status reads the active session state supplied by JSC-77."
open_questions_count: 0
source_issue_key: JSC-76
---

# Spec Draft: JSC-76

## Source
- Issue Key: JSC-76
- Title: Add `GET /status`, `GET /config`, and `GET /info` REST APIs
- Description:
  - `GET /status` returns a value that confirms the agent server started successfully, with a `session` field in the response body and HTTP 200.
  - `GET /config` returns the current agent configuration, including settings and runtime-data paths, autostart, REST-server enabled/port, debug, and silent-mode values, with HTTP 200.
  - `GET /info` returns the agent mode and tool ID, with HTTP 200.

## Goal
Add read-only session-state, configuration, and identity endpoints to the runtime-coverage agent HTTP server.

## In Scope
- Implement `GET /status` to return the active default-user session state.
- Implement `GET /config` to return the effective current agent configuration.
- Implement `GET /info` to return the agent mode and tool ID.
- Return HTTP 200 and JSON response bodies for all three endpoints.
- Preserve JSC-52's preloaded-agent HTTP-server model and its existing coverage get/reset responsibilities. (inferred)

## Out of Scope
- Adding or changing runtime coverage get/reset behavior from JSC-52.
- Any behavior not explicitly defined in JSC-76.

## Behavior
- `GET /status` responds with HTTP 200 and exactly `{ "session": null }` before a default-user session starts. After `GET` or `POST /session/start` succeeds, it responds with HTTP 200 and the active default-user session ID in the same `session` field. The temporary `status` and `temporary` fields are not returned.
- `GET /config` responds with HTTP 200 and exactly these effective-configuration fields: `settings`, `runtimeData`, `sessionAutostart`, `restServerEnabled`, `restServerPort`, `debugOn`, and `silentModeOn`. `settings` is `null` when no settings file is configured. When configured, `settings` and `runtimeData` are absolute paths. The former `jscov.agent.*` response keys are not returned.
- `GET /info` responds with `{ "agent-mode": "singleuser", "tool-id": "parasoft-jscov" }` and HTTP 200.
- The Node Agent owns an `AgentDescriptor` with its current `singleuser` mode and tool ID. `GET /info` maps that descriptor to the REST response instead of defining identity values in the route.
- All three endpoints are read-only and do not require the instrumented application's global coverage object to exist. (inferred)

## Edge Cases (Optional)
- All endpoints remain available before instrumented application code has created its global coverage object. (inferred)

## Done When (Acceptance Criteria)
- [ ] `GET /status` returns HTTP 200 with the `session` field set to `null` before a session starts and to the active default-user session ID afterward.
- [ ] `GET /config` returns HTTP 200 and exactly the specified camelCase body fields, including `settings: null` when settings are unset and absolute values for configured `settings` and `runtimeData` paths.
- [ ] `GET /info` returns HTTP 200 with agent mode `singleuser` and tool ID `parasoft-jscov`.
- [ ] Typed response mappers keep the REST field names separate from the Agent configuration, session, and identity models.
- [ ] Automated tests cover the JSON response body and HTTP status for all three endpoints. (inferred)

## Clarifications

### Assumptions
- None for this iteration.

### Design Decisions
- [D1] The Node Agent is the source of truth for its REST tool ID. The existing Java CLI jar filename is not imported as an identity source because no cross-language product-metadata contract exists.
- [D2] Agent mode is modeled only as the currently supported `singleuser` value. A later task may extend the model if multiuser support is introduced.
- [D3] `GET /config` maps internal configuration names to its own camelCase REST contract. In particular, `debug` maps to `debugOn` and `silentMode` maps to `silentModeOn`; the API does not expose its internal `jscov.agent.*` configuration keys.
- [D4] Configuration resolution normalizes configured `settings` and `runtimeData` paths with `node:path` `resolve()` before they reach the REST response. This supports non-existent runtime-data directories while preserving a logical (non-`realpath`) path.

### Unclear Points
- [U1] JSC-76 does not define how the `GET /status` session value is created. → **Resolved:** JSC-77 supplies the default-user session state. `/status` returns that active session ID, or `null` before session start.

### Missing Info
- None for this iteration.

### Questions for Human
- [Q1] (re [U1]) Should this task implement `GET /status` before the session model exists? → **Answered:** No. Implement it after JSC-77 is complete, with `session: null` before a session starts.

### Risks
- [R1] (re [U1]) Implementing `GET /status` without JSC-77 could create an incompatible session contract. **Mitigated:** query JSC-77's active default-user session service instead of duplicating session state.
