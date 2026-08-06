---
status: READY
status_reason: "The Java and JavaScript PR static-analysis scope, pipeline gates, artifacts, and violation handling have been reviewed and approved."
open_questions_count: 0
source_issue_key: JSC-63
---

# Spec Draft: JSC-63

## Source
- Issue Key: JSC-63
- Title: Add static analysis to the PR validation pipeline
- Description:
  Add a static analysis profile for the JSCov project and update the PR validation Jenkinsfile to run static analysis when static analysis validation is required.

  The Jenkinsfile should read `steps.csv` to determine whether static analysis is required. When `NEEDS_SA` is false, it should skip the static analysis stage. When it is true, it should run the JSCov static analysis profile, extract the violation count from `target/jtest/report.xml`, archive logs and reports under `artifacts/static/`, record the count in `artifacts/summary.md`, and, when violations are found, mark the Jenkins job unstable and set the pull-request status to `NEEDS_WORK` through the Bitbucket API.

  Ask Yuqian for a reference to the CTP team's Jenkinsfile when implementing this setup.

## Goal
Add conditional Java and JavaScript static analysis to JSCov pull-request validation, reporting violations through pipeline artifacts and Bitbucket review status. (inferred)

## In Scope
- Add a JSCov static analysis profile.
- Add a JSCov-owned Jtest static-analysis properties file under `jenkins/scripts/` and use it only from the PR pipeline. (inferred)
- Update the PR validation Jenkinsfile to read the second row of `steps.csv`, using the existing fixed positions for `NEED_JS_SA` and `NEED_JAVA_SA`. (inferred)
- Run Java Jtest static analysis when `NEED_JAVA_SA` is true and JavaScript ESLint static analysis when `NEED_JS_SA` is true. (inferred)
- Skip each language's static analysis when its corresponding flag is false. (inferred)
- Parse the Java violation count from `target/jtest/report.xml`, collect the JavaScript Checkstyle report, archive static-analysis artifacts, and record each language's violation count. (inferred)
- Mark the job unstable and update the pull-request status to `NEEDS_WORK` when either static-analysis type finds violations. (inferred)

## Out of Scope
- Not explicitly defined in Jira.

## Behavior
- The `Read PR Steps` stage extracts columns five and six from `artifacts/steps.csv`, reads the second value from each column (ignoring the header), and saves them as Jenkins environment variables. The static-analysis stages perform case-insensitive `true` checks against the named variables. (inferred)
- The PR pipeline resolves the Jenkins-managed `Jtest` tool and supplies `jenkins/scripts/jtest.properties` to the Java static-analysis command. (inferred)
- The Java static-analysis command receives `DTP_URL`, `DTP_USER`, and `DTP_PASSWORD` from its runtime environment; the repository-owned Jtest properties contain no DTP credentials. (inferred)
- `jenkins/jscov-pr.jenkinsfile` is limited to Pipeline flow, credentials, error handling, and calls to external shell scripts; the scripts own static-analysis execution and result processing. (inferred)
- A false language flag skips only that language's static-analysis stage in the Pipeline UI. (inferred)
- A true `NEED_JAVA_SA` value runs the JSCov Gradle/Jtest static-analysis profile using the repository-owned Jtest properties and extracts its violation count from `target/jtest/report.xml`. (inferred)
- A true `NEED_JS_SA` value runs the existing `:integration:lintReport` ESLint analysis and counts its Checkstyle violations. (inferred)
- Java logs and reports are archived under `artifacts/static/java/`; JavaScript reports are archived under `artifacts/static/js/`. (inferred)
- The PR pipeline does not publish analysis or test reports through Jenkins report publishers; it only archives raw artifacts and posts the markdown summary comment. (inferred)
- Each language's analysis script appends its own static-analysis result section to `artifacts/summary.md`. (inferred)
- An analysis execution failure or either language's non-zero violation count makes the Jenkins job unstable. (inferred)
- Before posting the final summary, the PR pipeline scans `artifacts/static/*/violations.txt`; when any count is non-zero, `post-pr-summary.sh` directly sets the bot review to `NEEDS_WORK` once. (inferred)

## Edge Cases
- If both static-analysis flags are false, no static-analysis command runs. (inferred)
- If exactly one language flag is true, only that language's artifacts and count contribute to the summary. (inferred)
- A missing expected report after its analyzer runs is an analysis failure and makes the job unstable. (inferred)

## Done When (Acceptance Criteria)
- [ ] PR validation reads the second `steps.csv` row and independently gates JavaScript and Java static analysis using the current column order. (inferred)
- [ ] The Java PR stage uses the repository-owned Jtest properties file and does not modify `jenkins/javascriptCoverageTest`. (inferred)
- [ ] The Java static-analysis profile runs when `NEED_JAVA_SA` is true and records the violation count from `target/jtest/report.xml`. (inferred)
- [ ] ESLint runs when `NEED_JS_SA` is true and records its violation count. (inferred)
- [ ] Static-analysis artifacts are retained below `artifacts/static/`, and `artifacts/summary.md` contains language-specific counts. (inferred)
- [ ] The PR Jenkinsfile has no inline analysis or report-publishing implementation; it calls the dedicated shell scripts and only archives artifacts. (inferred)
- [ ] Analysis failures or violations make the job unstable, and any violations set the pull-request status to `NEEDS_WORK`. (inferred)

## Clarifications

### Assumptions
- [A1] The CTP Jenkinsfile establishes the required implementation conventions for profile invocation, report parsing, artifact archival, unstable-result handling, and Bitbucket status updates. **Resolved:** It is a one-time reference only; JSC-63 has no runtime or source dependency on this removable file.

### Unclear Points
- [U1] The requested CTP Jenkinsfile reference has not been supplied, so its applicable patterns cannot yet be evaluated. **Resolved:** The local reference was reviewed. JSC-63 follows JSCov's own Jenkins configuration for Jtest settings and JavaScript linting.

### Missing Info
- [M1] The location or contents of the CTP team's reference Jenkinsfile are missing. **Resolved:** A local reference was supplied and confirmed as removable; its patterns have been captured in the approved JSCov-specific design.

### Questions for Human
- [Q1] (re [A1], [U1], [M1]) Please provide Yuqian's CTP-team Jenkinsfile reference (path, repository link, or contents) and identify which parts JSCov should follow. **Answered:** Use the supplied file only as a reference; do not retain a dependency on it.

### Risks
- [R1] (re [U1]) Implementing without the referenced pipeline conventions could produce incompatible artifact, status-update, or static-analysis behavior. **Mitigated:** The approved design uses JSCov's existing Jtest and ESLint patterns, with the CTP file excluded from the final dependency graph.
