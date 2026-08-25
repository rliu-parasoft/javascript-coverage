---
status: READY
status_reason: "The user resolved the concurrent-stop and persistence-diagnostic behavior."
open_questions_count: 0
source_issue_key: JSC-78
---

# Spec: JSC-78

## Source

- Issue Key: JSC-78
- Title: 4. Add GET/POST - /session/stop REST APIs
- Description:

  - Support both GET and POST methods
  - Stop the current session
  - Remove the current session id under the default user (`__default__`) from memory
  - Before stopping, save the `__coverage__` data from the node process into the `${sessionId}.json` file for local storage
  - Normal
    - Status code: 200
    - Body

      ```json
      {
          "session": null
      }
      ```

  - Cannot stop a session that has not been started
    - Status code: 404
    - Body

      ```json
      {
          "messageCode": 200,
          "message": "Cannot stop session because it was not started"
      }
      ```

## Corrections and Additions

- The API must return HTTP 404 with the user-not-found response when the default user has not successfully started a session in the running agent process. This includes automatic session start being disabled with no successful `/session/start` request.

  ```json
  {"messageCode":103,"message":"User '__default__' was not found"}
  ```

- `/session/stop` must create the user directory when it is absent before writing coverage. It checks the session JSON file only to emit a debug diagnostic when absent, then attempts the write regardless.
- The session JSON path is inspected with `lstatSync()` so a dangling symbolic link is distinguished from an `ENOENT` missing file.
- Concurrent requests must be handled safely.
- HTTP error responses include localized lifecycle context. File error logs retain the error trace; REST routes do not write lifecycle diagnostics to the console.

## Related Jira Context

### JSC-77 (implemented)

- Issue Key: JSC-77
- Title: 3. Add GET/POST - /session/start REST APIs
- Description:

  - Support both GET and POST methods
  - Record the current session id in memory. The format is:
    - `runtime_coverage_${timestamp}_${sequenceNumber}`
    - Store in Map format, key is userId, value is sessionId
    - The current default userId is `__default__`
  - Clear the hit information of `__coverage__` in the node process
  - Create a `__default__/${sessionId}.json` file to prepare for storing coverage data
    - `__default__` is the default user id
    - The file is located under the runtimeData folder
  - Normal
    - Status code: 200
    - Body

      ```json
      {
          "session": "runtime_coverage_8b39_20260807_1603_0"
      }
      ```

  - A session is already in active status and cannot be started repeatedly
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

### JSC-79

- Title: 4. Add GET - /coverage REST API
- Description:

  - List all session ids under the runtimeData folder
  - Response
    - Status code: 200
    - Body

      ```json
      [
          "runtime_coverage_8b39_20260807_1603_0"
      ]
      ```

### JSC-80

- Title: 4. Add GET - /coverage/{sessionId} REST API
- Description:

  - Get coverage of the specified session
  - Return a compressed package named with the session id
    - Contains runtime `.json` files
  - Normal: HTTP 200 with a ZIP file response
  - Session id not found: HTTP 404

  ```json
  {
      "messageCode": 400,
      "message": "Cannot get coverage because session is not found"
  }
  ```

### JSC-81

- Title: 5. Add DELETE - /coverage REST API
- Description:

  - Delete all locally stored session JSON files
  - Sessions that are not closed will not be deleted
  - Normal
    - Status code: 200
    - Body

      ```json
      {
          "skipped" : [
              {
                  "id" : "runtime_coverage_a413_20260807_1642_1",
                  "messageCode" : 300,
                  "reason" : "Session is not finished yet"
              }
          ],
          "deleted" : [
              "runtime_coverage_a413_20260807_1642_0"
          ]
      }
      ```

### JSC-82

- Title: 5. Add DELETE - /coverage/{sessionId} REST API
- Description:

  - Delete the local JSON file of the specified session
  - Normal
    - Status code: 200
    - Body

      ```json
      {
          "skipped" : [
          ],
          "deleted" : [
              "runtime_coverage_a413_20260807_1647_0"
          ]
      }
      ```

  - Session id not found
    - Status code: 400
    - Body

      ```json
      {
          "skipped" : [
              {
                  "id" : "runtime_coverage_da95_20260803_1728_0",
                  "messageCode" : 350,
                  "reason" : "Cannot delete session because it was not found"
              }
          ],
          "deleted" : [
          ]
      }
      ```

  - Delete a session in active status
    - Status code: 400
    - Body

      ```json
      {
          "skipped" : [
              {
                  "id" : "runtime_coverage_a413_20260807_1647_0",
                  "messageCode" : 301,
                  "reason" : "Session is not finished yet"
              }
          ],
          "deleted" : [
          ]
      }
      ```

## Goal

Provide GET and POST `/session/stop` endpoints that stop the default user's active session, persist its Node coverage data, and return the defined outcome when no stoppable session exists.

## Design Decision

- Extend the JSC-77 `SessionService`, which already owns the default-user active-session map and start reservation, instead of storing lifecycle state in Express routes.
- Add a per-user stopping reservation. The session remains active while coverage is persisted, so a concurrent stop receives the existing not-started HTTP 404 / message code `200` response and later JSC-81/JSC-82 deletion APIs can identify it as unfinished.
- Create the resolved user directory with recursive directory creation before persistence, without a separate directory-existence check. Check only the expected session JSON path; a missing file produces a debug diagnostic and does not prevent the write attempt.
- Persist coverage before removing the active-session entry. If writing fails, log the write failure as an error, release the stopping reservation, and retain the active session for a retry.
- Keep the synchronous local-file transition small and atomic within the Node process. Future coverage listing, retrieval, and deletion APIs use persisted files plus the shared active-session state rather than duplicate lifecycle decisions.

## In Scope

- Register GET and POST handlers for `/session/stop`.
- Save the active session's `__coverage__` data as local `${sessionId}.json` storage before session removal.
- Remove the default user's current session ID from in-memory state.
- Return the specified successful and error responses.
- Add debug and error diagnostics with the user ID and, when available, the session ID, without logging coverage content. (inferred)
- Preserve JSC-77's shared in-memory lifecycle state for later coverage listing, retrieval, and deletion APIs. (inferred)

## Out of Scope

- Not explicitly defined in Jira.

## Behavior

- A GET or POST request to `/session/stop` stops the current default-user session.
- Before the session is stopped, its `__coverage__` data is persisted to `${sessionId}.json`.
- A successful stop removes the default user's current session ID from memory and returns HTTP 200 with `{"session": null}`.
- If the default user is known to the running agent but has no active session, return HTTP 404 with message code `200` and the localized message `Cannot stop a session for user '__default__' because it was not started`.
- If the default user has not successfully started a session in the running agent process, return HTTP 404 with message code `103` and the localized message `User '__default__' was not found`. This includes automatic session start being disabled with no successful `/session/start` request.
- The session JSON path is checked only to emit a debug message when the file is absent; a missing file does not prevent the persistence attempt.
- The session JSON path uses `lstatSync()` to distinguish an `ENOENT` missing file from a dangling symbolic link; any symbolic link is rejected before writing.
- The endpoint creates the user directory if it is absent before attempting the session JSON write.
- A failure to write the session JSON file is logged as an error with its trace in the file log, leaves the session active, and returns the route's contextual internal-error response. (inferred)
- Debug and error diagnostics identify the user/session or the concrete session-file path; when no session ID exists, they omit it and never include coverage content. (inferred)
- A concurrent stop observes the stopping reservation and returns the same HTTP 404 / message code `200` not-started response; it does not perform a second write. (inferred)

## Edge Cases (Optional)

- Requests that race to stop the same session must not produce a partially removed session or conflicting coverage persistence. The first request owns the stopping reservation; later requests receive the not-started HTTP 404 / message code `200` response. (inferred)
- If a reserved session JSON file was removed, debug logging records its absence and the coverage write recreates it when the parent directory remains available.
- If the user directory is removed, the stop operation recreates it before writing coverage.

## Done When (Acceptance Criteria)

- [x] GET `/session/stop` returns HTTP 200 and `{"session": null}` after stopping an active session.
- [x] POST `/session/stop` returns HTTP 200 and `{"session": null}` after stopping an active session.
- [x] The active session's Node `__coverage__` data is persisted before its ID is removed from memory.
- [x] No active session for a default user known to the running agent returns the defined HTTP 404 / message code `200` response.
- [x] A default user that has not successfully started a session in the running agent process, including disabled automatic start with no successful `/session/start` session, returns the defined HTTP 404 / message code `103` response.
- [x] A missing session JSON file produces a debug diagnostic but does not prevent the write attempt.
- [x] A session JSON symbolic link, including a dangling link, is rejected rather than treated as missing.
- [x] A failed session JSON write produces an error log and leaves the session active.
- [x] A missing user directory is created and the coverage write proceeds.
- [x] Concurrent stop requests preserve a consistent session state and coverage result; only one writes coverage. (inferred)
- [x] The active/stopping session state remains suitable for JSC-79 through JSC-82 coverage listing, retrieval, and deletion behavior. (inferred)

## Clarifications

### Assumptions

- [A1] The default user is the only user in scope because Jira explicitly identifies `__default__`. → **Resolved:** use JSC-77's existing `__default__` session map.

### Unclear Points

- [U1] The response expected from a second request that races with a successful stop is not specified. → **Resolved:** the first request owns a stopping reservation; the concurrent request returns HTTP 404 with message code `200` and does not write coverage.

### Missing Info

- None for this iteration.

### Questions for Human

- [Q1] (re [U1]) If two GET/POST `/session/stop` requests race for the same active session, should the request processed second return the existing HTTP 404 / message code `200` response after the first succeeds, or should both be treated as successful? → **Answered:** return the existing HTTP 404 / message code `200` response.

### Risks

- [R1] (re [U1]) Different concurrent-response expectations could make otherwise safe session locking appear incorrect to API clients. → **Mitigated:** the response and reservation behavior are explicit and will be covered by concurrent route tests.
