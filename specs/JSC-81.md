---
status: READY
status_reason: "The concurrency contract is resolved: session lifecycle mutations and deletion use the service's synchronous, run-to-completion critical sequence."
open_questions_count: 0
source_issue_key: JSC-81
---

# Spec Draft: JSC-81

## Source

- Issue Key: JSC-81
- Title: 5. Add DELETE - /coverage REST API
- Description:
  - Delete all locally stored session JSON files.
  - Do not delete sessions that are not closed.
  - On success, return HTTP 200 with a body that lists the skipped sessions (including their ID, message code, and reason) and the deleted session IDs.

### Jira Response Example

```json
{
  "skipped": [
    {
      "id": "runtime_coverage_a413_20260807_1642_1",
      "messageCode": 300,
      "reason": "Session is not finished yet"
    }
  ],
  "deleted": [
    "runtime_coverage_a413_20260807_1642_0"
  ]
}
```

## Goal

Provide a `DELETE /coverage` REST API that removes locally stored JSON files for closed coverage sessions while reporting closed-session deletion results and sessions that remain active.

## In Scope

- Add the `DELETE /coverage` REST endpoint.
- Delete the locally stored session JSON file for each closed session belonging to the target user.
- Preserve every session that is not closed and report it in `skipped` with message code `300` and reason `Session is not finished yet`.
- Return HTTP 200 with `deleted` session IDs and `skipped` session-result objects when the target user and user directory exist.
- When no user or user directory exists, return HTTP 404 with message code `307` and the existing localized user-not-found message. For the default English configuration, the response is:

  ```json
  {
    "messageCode": 307,
    "message": "Cannot delete coverage because user '__default__' is not found"
  }
  ```

- If deleting a closed session file fails, report that session with message code `302` and a reason equivalent to `Session file ''{0}'' cannot be removed`.
- After the final session JSON file is removed, delete the user directory and remove the user from the internal user map/set when the directory is empty. Preserve unrelated runtime-data files. (inferred)
- Keep cleanup and user-state updates safe when requests or session state changes occur concurrently: use the synchronous service lifecycle sequence without yielding between selecting sessions, checking their state, deleting files, and cleaning up the user. (inferred)

## Out of Scope

- Not explicitly defined in Jira.

## Behavior

- The endpoint enumerates the target user's locally stored session JSON files using the existing regular `runtime_coverage_*.json` filename convention; it does not restrict bulk selection to canonical session-ID syntax. (inferred)
- A session that is not closed remains stored and is returned in `skipped` as `{ "id", "messageCode": 300, "reason": "Session is not finished yet" }`.
- Immediately before removal, deletion checks whether the selected session is active, stopping, or reserved. An in-progress session remains stored; a session that becomes finished after it was skipped is eligible on a later delete request. (inferred)
- A successfully deleted closed session is returned by ID in `deleted`.
- A closed session whose JSON file cannot be removed remains stored and is reported in `skipped` with message code `302` and a file-removal reason. A selected session file that no longer exists is reported with message code `350`. (inferred)
- If the target user is absent or its directory does not exist, the endpoint returns HTTP 404 and message code `307` with the existing localized user-not-found message.
- After the last session JSON file has been removed, the implementation unregisters the user and removes the directory when it is empty; a subsequent stop request therefore returns the existing user-ID-not-found response with message code `103`. Unrelated files prevent directory removal but are preserved. (inferred)
- Session lifecycle operations and deletion are synchronous, run-to-completion service operations. A concurrent request runs after the current operation completes and observes its resulting filesystem and user-registry state. (inferred)
- The final-file cleanup runs in that same sequence. A later concurrent delete therefore returns the HTTP 404/user-not-found response after cleanup. (inferred)

## Edge Cases (Optional)

- The user exists in memory but the user directory does not: return HTTP 404/message code `307`.
- The user directory exists but the user is no longer registered: return HTTP 404/message code `307`.
- All sessions are open: return HTTP 200 with an empty `deleted` list and all sessions in `skipped`.
- The final closed session is deleted: remove the empty directory and unregister the user.
- A file deletion fails: retain the session and report message code `302`.
- A session that becomes closed only after it has been observed as in progress remains for the current request and is eligible for a later delete request. (inferred)
- A concurrent lifecycle operation that has reserved a session file keeps that file visible and protected from deletion. (inferred)
- A second bulk-delete request after final cleanup returns HTTP 404/message code `307`. (inferred)

## Done When (Acceptance Criteria)

- [ ] `DELETE /coverage` deletes the locally stored JSON files for closed sessions.
- [ ] Open sessions are retained and reported as skipped with message code `300` and reason `Session is not finished yet`.
- [ ] A normal request returns HTTP 200 with `deleted` and `skipped` response fields.
- [ ] A missing user or user directory returns HTTP 404 with message code `307` and the specified message.
- [ ] A failed session-file removal is reported with message code `302` and a session-file removal reason.
- [ ] Removing the final session file deletes the user directory and unregisters the user, so a later stop request returns message code `103`.
- [ ] Concurrent requests execute as synchronous service operations, preserving active or reserved sessions and leaving consistent user-directory and in-memory state. (inferred)

## Corrections and Additions

The following requirements were supplied outside the Jira description and refine it:

- Treat a missing user and a missing user directory identically: HTTP 404 with message code `307` and the existing `coverage_delete_user_not_found` localization, which includes the default user ID.
- Delete the user directory and remove the user from the internal map/set after the last session JSON file is deleted. The implementation deletes the directory only when it is empty, so unrelated runtime-data files are preserved.
- Consider concurrent deletion and session lifecycle activity. The adopted contract is a synchronous, run-to-completion lifecycle sequence; it does not introduce an asynchronous per-user lock.
- Handle failed session-file removal with message code `302` and the specified reason pattern.
- Bulk deletion uses the established regular runtime-coverage JSON filename convention rather than canonical session-ID validation. (inferred)
- If a selected session file disappears before removal, report it with message code `350`. (inferred)

## Clarifications

### Assumptions

- [A1] The endpoint's target user is determined by the existing coverage REST API contract rather than by a new request parameter. → **Resolved:** Use the existing default-user contract.

### Unclear Points

- [U1] A session may become closed after the endpoint has observed it as active; the issue does not state whether that request should delete it or defer deletion to a later request. → **Resolved:** Skip it for the current request; it is eligible for a later delete request after its stop operation completes.

### Missing Info

- None for this iteration.

### Questions for Human

- None for this iteration.

### Risks

- [R1] (re [U1]) An asynchronous yield added to the deletion sequence could allow lifecycle operations to interleave with cleanup, causing inconsistent user-directory state. The implementation must remain synchronous through selection, state checks, deletion, and cleanup.
