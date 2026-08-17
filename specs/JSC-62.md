---
status: READY
status_reason: "The execution model, baseline source, JavaScript placeholder behavior, and failure handling have been confirmed."
open_questions_count: 0
source_issue_key: JSC-62
---

# Spec Draft: JSC-62

## Source
- Issue Key: JSC-62
- Title: Add TIA-based test execution to the PR validation pipeline
- Description: Add a TIA profile for the JSCov project and update the PR validation Jenkinsfile to run TIA-based test execution when test validation is required. The Jenkinsfile must read `steps.csv`; skip TIA when `NEEDS_TEST` is false; otherwise download `coverage.xml` and `report.xml` from the latest applicable nightly build, run the JSCov TIA profile, archive reports under `artifacts/tia-run`, record the result in `artifacts/summary.md`, and, if selected tests fail, mark the Jenkins job unstable and set the pull-request status to `NEEDS_WORK` through the Bitbucket API. The CTP team's Jenkinsfile is the implementation reference.

## Goal
Add a JSCov TIA profile and conditionally run it from PR validation so only required tests are executed using the latest applicable nightly-build baseline.

## In Scope
- Add a Jtest TIA execution profile for the Java portion of the JSCov project.
- Update the PR validation Jenkinsfile to load and validate the test-execution flags from `steps.csv`.
- Skip the TIA execution stage when `NEEDS_TEST` is `false`.
- Download `coverage.xml` and `report.xml` from the latest applicable nightly build when `NEEDS_TEST` is `true`.
- Run the JSCov TIA profile with the downloaded baseline files.
- Archive TIA reports under `artifacts/tia-run`.
- Record the TIA result in `artifacts/summary.md`.
- On selected-test failure, mark the Jenkins job unstable and set the PR status to `NEEDS_WORK` through the Bitbucket API.
- Add a JavaScript TIA placeholder only; the JSCov TIA tool is still under development.
- Publish the Java and JavaScript coverage, test, and static-analysis reports using the same Jenkins quality-gate conventions as `javascriptCoverageTest`.
- Preserve the existing pipeline declaration structure, including its `parameters` block and `stage('Load Execution Plan')` pattern.

## Out of Scope
Not explicitly defined in Jira.

## Behavior
- The PR validation pipeline loads the `NEED_*` flags from `artifacts/steps.csv`; a missing or malformed plan fails validation rather than silently skipping tests.
- The Jenkinsfile keeps the established parameter declaration format for Jtest and DTP configuration, including its credential parameter type and defaults.
- `stage('Load Execution Plan')` reads the non-empty CSV lines, maps the header row to the value row, and exports each flag to `env` before conditional stages execute.
- Java full-test flags take priority over Java TIA flags.
- For Java TIA, the pipeline downloads `reports/unit/coverage.xml` and `reports/unit/report.xml` from the latest successful `javascript.coverage.test` build, then invokes Jtest TIA with those baseline files.
- The pipeline preserves the TIA reports at `artifacts/tia-run` and writes the execution result to `artifacts/summary.md`.
- A selected-test failure leaves the job unstable and updates the PR status to `NEEDS_WORK`.
- When only `NEED_JS_TEST_TIA` is true, the pipeline records a `TODO(JSC-62)` JSCov-TIA placeholder and does not run Mocha; when `NEED_JS_TEST_FULL` is true, it runs the full Mocha suite.
- The PR pipeline records Parasoft coverage, Clover coverage, ESLint findings, and JUnit results using the report conventions from `javascriptCoverageTest`; the existing ESLint total-issue quality gate remains unstable at one issue.

## Edge Cases
- If the latest successful `javascript.coverage.test` build lacks either baseline artifact, the Java TIA run fails.
- If both Java TIA and Java full-test flags are true, only the full Java test path runs.
- If both JavaScript TIA and JavaScript full-test flags are true, only the full JavaScript test path runs.

## Done When (Acceptance Criteria)
- [ ] PR validation loads and validates the `steps.csv` execution plan.
- [ ] Java PR changes run Jtest TIA with baseline coverage and report files from the latest successful `javascript.coverage.test` build.
- [ ] Java configuration changes run the full Jtest test path instead of TIA.
- [ ] TIA reports are archived at `artifacts/tia-run` and the result is recorded in `artifacts/summary.md`.
- [ ] A selected-test failure marks the job unstable and sets the PR status to `NEEDS_WORK`.
- [ ] JavaScript TIA-only changes produce a JSCov-TIA placeholder without running Mocha; JavaScript full-test changes run the full Mocha suite.
- [ ] The PR pipeline publishes the coverage, test, and static-analysis reports with the `javascriptCoverageTest` quality-gate conventions.
- [ ] The Jenkinsfile retains the established `parameters` and `Load Execution Plan` formatting and behavior before the test stages.

## Clarifications

### Assumptions
- [A1] The existing Bitbucket API integration in the PR validation pipeline can set a PR status to `NEEDS_WORK`. → **Resolved:** Reuse the CTP-style Bitbucket participant-status update with the JSC repository API endpoint and existing PR bot credential.

### Unclear Points
- [U1] "Latest applicable nightly build" does not define the job, branch, artifact source, or matching rule. → **Resolved:** Use the latest successful `javascript.coverage.test` build and its `reports/unit/coverage.xml` and `reports/unit/report.xml` artifacts.
- [U2] The exact JSCov TIA profile configuration and invocation are not defined. → **Resolved:** Implement Java TIA through Jtest; JSCov TIA is not yet available and receives a `TODO(JSC-62)` placeholder only.

### Missing Info
- [M1] The required behavior when `steps.csv` is missing, malformed, or does not contain `NEEDS_TEST` is not provided. → **Resolved:** Fail validation loudly.

### Questions for Human
- [Q1] (re [A1]) Which existing Bitbucket API helper or status convention should the pipeline use to set `NEEDS_WORK`? → **Answered:** Follow the CTP pattern using the JSC repository endpoint and current PR credential.
- [Q2] (re [U1], [U2]) Should JSC-62 follow the CTP Jenkinsfile's nightly-build selection and TIA profile configuration exactly, adapting only project-specific paths and names? → **Answered:** Yes; use Jtest TIA for Java and the `javascript.coverage.test` baseline. JSCov TIA remains a placeholder.
- [Q3] (re [M1]) If `steps.csv` or `NEEDS_TEST` is unavailable or invalid, should the pipeline fail validation, mark it unstable, or conservatively run TIA? → **Answered:** Fail validation.

### Risks
- [R1] (re [U1]) A missing or incompatible baseline artifact blocks the Java TIA run.
- [R2] (re [U2]) JSCov TIA cannot be activated until its tool is released; JavaScript TIA-only changes intentionally do not run Mocha.