---
status: READY
status_reason: "Implemented and verified: the single-session DELETE route delegates to a reusable synchronous, selection-based SessionService deletion operation, preserving lifecycle consistency and localized response contracts."
open_questions_count: 0
source_issue_key: JSC-82
---

# Specification: JSC-82

## Source

- Issue Key: JSC-82
- Title: 5. Add DELETE - /coverage/{sessionId} REST API
- Description:

Delete the local JSON file of the specified session.

### Normal

Status code: `200`

Body:

```json
{
    "skipped" : [
    ],
    "deleted" : [
        "runtime_coverage_a413_20260807_1647_0"
    ]
}
```

### Session ID not found

Status code: `400`

Body:

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

### Delete a session in active status

Status code: `400`

Body:

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

Add `DELETE /coverage/{sessionId}` so clients can remove a completed runtime-coverage session JSON file and its unused user state.

## In Scope

- Expose `DELETE /coverage/{sessionId}` in the runtime coverage REST service.
- Delegate the single-session route to the reusable `SessionService` deletion operation; the explicit collection operation is reserved as the foundation for future collection deletion and does not expose a new JSC-81 route.
- Delete the local JSON file for a completed session and report its ID in `deleted` with HTTP 200.
- Reject an unknown session ID with HTTP 400 and the specified skipped-session response, message code 350, and reason.
- Reject deletion of an active session with HTTP 400 and the specified skipped-session response, message code 301, and reason.
- Return HTTP 404 with message code 307 and a localized message identifying the missing user, such as `Cannot delete coverage because user '__default__' is not found`, when the session user or its directory is absent.
- Return a skipped-session response with message code 303 and a reason identifying the session file when the file cannot be inspected or removed.
- When deletion removes the final session JSON file for a user, unregister the user from in-memory tracking; remove the user directory only when no unrelated runtime-data files remain.
- Protect deletion and user-state cleanup from concurrent lifecycle requests. (inferred)
- Include useful session and user context in response reasons or messages when it does not change the required response contract. (inferred)

## Out of Scope

- Not explicitly defined in Jira.

## Behavior

- A request identifies one session by `{sessionId}`.
- The endpoint is `DELETE /coverage/{sessionId}` and invokes the reusable service operation with one session ID for the default user. A separate explicit collection operation supports future collection deletion; this JSC-82 change does not expose a new JSC-81 route.
- A finished session with a removable JSON file is deleted. The response is HTTP 200 with `skipped: []` and `deleted` containing the session ID.
- An unknown session returns HTTP 400. The response has one `skipped` entry with the session ID, message code 350, and reason `Cannot delete session because it was not found`, followed by `deleted: []`.
- An active session returns HTTP 400. The response has one `skipped` entry with the session ID, message code 301, and reason `Session is not finished yet`, followed by `deleted: []`.
- If the user or user directory cannot be found, the response is HTTP 404 with message code 307 and a localized message identifying the missing user.
- If the session file cannot be inspected or removed, the response records a skipped session with message code 303 and a reason identifying that session file.
- If no session JSON files remain after a successful deletion, the implementation removes the user from internal tracking; it deletes the user directory only when it is empty, preserving unrelated runtime-data files. A later stop request for that user returns its existing user-not-found response (message code 103).
- The service keeps validation, file deletion, and final-user cleanup in synchronous operations with no async gap. It treats a matching reserved/starting session or active/stopping session as in progress, so a concurrent or reentrant lifecycle operation cannot delete it. (inferred)
- User-facing response text is localized in every supported locale; exact English contracts remain the English-resource values. (inferred)

## Edge Cases (Optional)

- The session becomes active or its file is removed by another request while deletion is in progress. (inferred)
- The final-session cleanup races with another request that creates or accesses session state for the same user. (inferred)
- Filesystem removal fails because of an I/O error or file lock. (inferred)

## Done When (Acceptance Criteria)

- [x] `DELETE /coverage/{sessionId}` deletes a finished session JSON file and returns the specified HTTP 200 response.
- [x] Unknown sessions return the specified HTTP 400, message-code-350 skipped response.
- [x] Active sessions return the specified HTTP 400, message-code-301 skipped response.
- [x] Missing users or user directories return the specified HTTP 404 message-code-307 response.
- [x] Failed session-file inspection or removal returns a skipped response with message code 303 and an identifying reason.
- [x] Deleting a user's last session unregisters the user and removes an empty directory, so a following stop request receives message code 103; unrelated runtime-data files are preserved.
- [x] Concurrent lifecycle requests preserve consistent session and user tracking. (inferred)
- [x] Automated tests cover successful deletion, each required failure response, final-user cleanup, and relevant concurrency behavior. (inferred)
- [x] The agent README documents `DELETE /coverage/{sessionId}` without machine-specific paths. (inferred)

## Corrections and Additions

### Corrections

- The Jira description does not define the missing-user HTTP 404 response or the session-file-removal failure response. This specification adds the supplied required contracts without changing the Jira-defined 200 and 400 responses.
- The 404/message-code-307 response identifies the missing user so its API message and debug diagnostic contain the same user context.

### Additions

- User-directory removal and in-memory user unregistration after the final session is deleted.
- Concurrent lifecycle safety for session deletion and final-user cleanup.
- Session and user context in response text where compatible with the required contracts.

## Clarifications

### Assumptions

- [A1] The existing runtime coverage service owns session state and user-directory tracking, and the endpoint will reuse those mechanisms. → **Resolved:** `SessionService` owns the generic deletion operation; the REST route supplies the default user and maps its result to HTTP.

### Unclear Points

- None for this iteration.

### Missing Info

- None for this iteration.

### Questions for Human

- None for this iteration.

### Risks

- [R1] (re [A1]) Existing synchronization boundaries may need to be extended so final-user cleanup cannot race with start, stop, or deletion requests.
