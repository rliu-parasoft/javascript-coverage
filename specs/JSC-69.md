---
status: READY
status_reason: "The Jira description identifies the coverage-data location, validation requirement, affected method, and documentation update."
open_questions_count: 0
source_issue_key: JSC-69
---

# Spec Draft: JSC-69

## Source
- Issue Key: JSC-69
- Title: Using the project root as the -app argument
- Description:
  - Always read all static coverage JSON files from `<rootPath>/.parasoft/static-coverage`.
  - When validating the `-app` argument in `JavascriptCoverageDataEngine.verifyOptions()`, verify that `<rootPath>/.parasoft/static-coverage` exists.
  - Update documentation.

## Goal

Support using the project root as the `-app` argument by locating static coverage data in its `.parasoft/static-coverage` directory.

## In Scope

- Read all static coverage JSON files from `<rootPath>/.parasoft/static-coverage`.
- Validate the presence of `<rootPath>/.parasoft/static-coverage` in `JavascriptCoverageDataEngine.verifyOptions()` when processing `-app`.
- Update user documentation to describe the project-root `-app` argument behavior.
- Add or update tests that prove the new path resolution and validation behavior. (inferred)

## Out of Scope

- Not explicitly defined in Jira.

## Behavior

- The static coverage data reader resolves coverage JSON files beneath `<rootPath>/.parasoft/static-coverage`.
- `JavascriptCoverageDataEngine.verifyOptions()` rejects an `-app` value whose `<rootPath>/.parasoft/static-coverage` directory is absent.
- Documentation explains that `-app` receives the project root and identifies the required static-coverage directory beneath it.

## Edge Cases (Optional)

- A project root exists but its `.parasoft/static-coverage` directory is missing; option validation fails before coverage data is read. (inferred)

## Done When (Acceptance Criteria)

- [ ] All static coverage JSON files are read from `<rootPath>/.parasoft/static-coverage`.
- [ ] `JavascriptCoverageDataEngine.verifyOptions()` verifies that `<rootPath>/.parasoft/static-coverage` exists for the supplied `-app` project root.
- [ ] User-facing documentation is updated.
- [ ] Automated tests cover successful project-root validation and rejection when the required directory is missing. (inferred)

## Clarifications

### Assumptions

- None.

### Unclear Points

- None.

### Missing Info

- None.

### Questions for Human

- None for this iteration.

### Risks

- Existing consumers that pass the static-coverage directory itself rather than the project root may require migration; compatibility expectations are not stated in Jira. (inferred)
