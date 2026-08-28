---
status: READY
status_reason: "The archive layout, exclusion rules, error contracts, and ZIP implementation approach have been confirmed."
open_questions_count: 0
source_issue_key: JSC-80
source_issue_assignee: rliu
---

# Spec Draft: JSC-80

## Source
- Issue Key: JSC-80
- Title: 4. Add GET - /coverage/{sessionId} REST API
- Description:
  - Get coverage of the specified session.
  - Return a compressed package named with the session id, containing runtime `.json` files.
  - On success, return HTTP 200 and a binary ZIP download.
  - If the session id is not found, return HTTP 404 with message code `400` and message `Cannot get coverage because session is not found`.

## Goal
Provide session archive download through `GET /coverage/{sessionId}` so callers can retrieve the requested session's runtime coverage snapshot as a ZIP package.

## In Scope
- Add `GET /coverage/{sessionId}` to the JSCov agent REST service.
- Produce a streaming session archive download named `<sessionId>.zip`.
- Include `version.json` and the requested session JSON while preserving the runtime-data directory layout.
- Return the confirmed 404 contracts for an unregistered user or missing session runtime data, with the user result taking precedence over session-ID validation.
- Return the confirmed 405 contract when the required `version.json` file is absent.
- Add the approved MIT-licensed ZIP writer and its TypeScript declarations.
- Cover the endpoint's archive contents, headers, exclusions, and error contracts with localized-message expectations.

## Out of Scope
- Including `agent_*.log`, other sessions, or `instrumentation_*.json` in the archive.
- Validating or interpreting the contents of `<sessionId>.json` before adding it to the archive.

## Behavior
- The route resolves session data only beneath the default-user runtime directory, `runtimeData/__default__`, and rejects session IDs that could escape that location.
- A successful session archive download returns HTTP 200, `Content-Type: application/zip`, and an attachment filename of `<sessionId>.zip`.
- The ZIP preserves this layout, where `<runtimeDataName>` is the configured runtime-data directory's basename:

  ```text
  <runtimeDataName>/
  ├─ version.json
  └─ __default__/
     └─ <sessionId>.json
  ```

- The ZIP excludes agent logs, other sessions, and nonexistent `instrumentation_*.json` files.
- The session JSON is packaged as-is; an empty JSON object remains downloadable and is not treated as an error.
- If the default user is not registered in the running agent, or its runtime-data directory is absent, return HTTP 404 with `messageCode: 401` and the localized equivalent of `Cannot get coverage because user is not found`, before validating the requested session ID, even when stale files exist in its runtime-data directory.
- If the requested session JSON does not exist, including when the session lacks runtime data, return HTTP 404 with `messageCode: 400` and the localized equivalent of `Cannot get coverage because session is not found`.
- If `version.json` is absent for an otherwise valid requested session, return HTTP 405 with `messageCode: 701` and the localized `version_file_not_found` message. Retain 405 to preserve the existing download-error contract, not to indicate that GET is disallowed. Use the resolved absolute runtime-data path in both the message and file access.
- Failures while creating or reading the archive follow the existing internal-error logging and HTTP 500 pattern.

## Edge Cases (Optional)
- A session file may disappear after its existence check; archive-stream failures follow the internal-error path.

## Done When (Acceptance Criteria)
- [ ] `GET /coverage/{sessionId}` returns HTTP 200 and a downloadable `<sessionId>.zip` for an existing session JSON.
- [ ] The ZIP contains exactly `<runtimeDataName>/version.json` and `<runtimeDataName>/__default__/<sessionId>.json` for the requested session.
- [ ] The ZIP excludes `agent_*.log`, all other sessions, and `instrumentation_*.json`.
- [ ] An empty session JSON remains downloadable without content validation.
- [ ] An unregistered default user or absent default-user directory returns HTTP 404, `messageCode: 401`, and the localized user-not-found message even when stale files exist or the requested session ID is invalid.
- [ ] A missing session JSON returns HTTP 404, `messageCode: 400`, and the localized session-not-found message.
- [ ] A missing `version.json` for an otherwise valid session returns HTTP 405, `messageCode: 701`, and identifies `version.json` beneath the resolved absolute runtime-data path.
- [ ] Archive creation or source-reading errors use the existing HTTP 500 and diagnostic-logging convention.

## Clarifications

### Assumptions
- [A1] The ZIP includes only runtime `.json` files belonging to the requested session. → **Resolved:** Include the requested session JSON and `version.json` in the preserved runtime-data layout; exclude logs, other sessions, and `instrumentation_*.json`.

### Unclear Points
- [U1] "Named with the session id" does not define the exact download filename convention. → **Resolved:** Use `<sessionId>.zip`.

### Missing Info
- [M1] The expected HTTP result when a valid session has no runtime `.json` files is not stated. → **Resolved:** A missing session JSON returns the session-not-found 404; an existing JSON file is downloadable without inspecting its contents.

### Questions for Human
- [Q1] (re [A1]) Should the ZIP contain only the requested session's runtime `.json` files, or are other coverage artifacts expected too? → **Answered:** Package the confirmed session runtime layout, including `version.json`, and exclude logs, other sessions, and `instrumentation_*.json`.
- [Q2] (re [U1]) Is the intended download filename exactly `<sessionId>.zip`, or should it use another convention? → **Answered:** Use `<sessionId>.zip`.
- [Q3] (re [M1]) If the session exists but has no runtime `.json` files, should the endpoint return an empty ZIP, a specific error, or another response? → **Answered:** Treat a missing session JSON as session-not-found; do not inspect an existing session JSON's contents.
- [Q4] Should a missing-version-file error show the resolved or configured runtime-data path? → **Answered:** Use the resolved absolute path regardless of whether configuration received a relative or absolute path.

### Risks
- [R1] A source file can change after validation and before archive streaming begins; surface the failure through the established internal-error diagnostic path.
