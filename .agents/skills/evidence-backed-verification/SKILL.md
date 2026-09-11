---
name: evidence-backed-verification
description: Use when acting as a verification lead before merging a build, package, artifact, deployment-like layout, startup command, user workflow, integration, or reference-contract change that must be proven through a built deliverable.
---

# Evidence-Backed Verification

Act as the team lead for functional verification. The goal is not merely to make tests pass; it is to establish whether the implementation is ready to merge, what evidence supports that decision, and which risks remain. A passing test suite proves only the assertions it executed.

## Verification lenses

Before claiming merge confidence, inspect the lenses that apply to the change and record their results separately:

| Lens | Verify |
|---|---|
| Implementation | Changed routes, public functions, configuration, error paths, and lifecycle behavior |
| Declared contract | Paths, methods, parameters, request/response schemas, status codes, media types, headers, examples, and binary responses |
| Reference/expected-behavior parity | Every shared operation against the authoritative reference artifact or acceptance baseline; also classify reference-only and implementation-only items |
| Runtime behavior | The built or started artifact over its real interface, including status, headers, body shape, and failure behavior |
| Negative and boundary behavior | Invalid inputs, missing resources, unsupported methods, empty state, error paths, content negotiation, signal handling, and security-sensitive output |
| Delivery and merge risk | Build/package layout, startup command, dependency resolution, clean workspace, logs, changed files, and untested environments |

Do not let one lens substitute for another. Tests do not prove contract parity, a parsed contract does not prove runtime behavior, and a reference screenshot does not prove the raw reference definition.

## User-path verification gate

The primary subject under test is the delivered product as a user can reach it, not an individual source file.

1. Build the product using the repository's supported build or packaging path.
2. Construct an isolated simulated-user workspace from the build output and required runtime files. Record its tree and manifests.
3. Start the built product using the command line, configuration, and working-directory form available to the user.
4. Reach the target behavior through its public entry point: CLI, HTTP endpoint, browser workflow, packaged command, or other documented interface.
5. Capture user-visible outputs, status, headers, files, logs, and process state from that workflow.

Source imports, direct calls to internal services, single-file parsers, and unit tests may explain a result or provide supporting evidence, but they cannot be the only proof of an integration or delivery claim. If the build or user-path startup fails, do not fall back to source-level checks and call the delivered workflow `PASS`.

A mechanism that serves or discovers the contract is only a way to obtain the contract. Do not infer that this mechanism belongs as an operation in the published contract unless the user explicitly requires it.

## Coverage scope and deferred checks

Verification is risk-based, not an exhaustive checklist. Before execution, divide the scope into:

- **Required user-path checks**: build/package, startup, primary success workflow, and the highest-risk failure or compatibility behavior.
- **Representative checks**: a small set of boundary cases that gives confidence in the same user-facing mechanism.
- **Deferred details**: exhaustive status/schema/locale/platform permutations or low-risk variants that are not necessary for this merge decision.

The detailed plan and report must list deferred details with a reason and the label `Manual decision required`. A representative user-path run must never be described as exhaustive coverage.

## When a reference or expected behavior is part of the request

Treat any claim that the implementation does not match expected behavior as a verification claim, not as a styling suggestion.

1. Obtain the exact reference artifact from its authoritative source. Record its version, producing revision/build when available, source location, and checksum. Preserve the raw artifact read-only.
2. Compare the complete shared surface, not only the most visible operation. For every path and method present on both sides, compare parameter names/locations/requiredness, request bodies, every response status, media types, headers, schema structure, required and nullable fields, examples, and binary formats.
3. Classify one-sided items explicitly as reference-only or implementation-only. Never silently ignore an extra or missing path, method, parameter, status, or response field.
4. Resolve references before comparing schemas where possible. If the reference is invalid or cannot be parsed, retain the raw file, report the parser limitation, and use a structural/manual comparison only with a `CONDITIONAL PASS` or `FAIL` boundary. Do not claim exact parity from a screenshot or a partial parse.
5. Compare the declared contract with wire behavior separately. A reference may declare one status while the implementation returns another status with an application-level code; report both facts rather than collapsing them into “matches.”
6. For every reference-only status, error response, parameter, or mode-dependent behavior, trace whether the current implementation has a reachable trigger and a public way to observe it. Inspect the relevant code and configuration, then exercise the built public interface when practical. If no branch, mode, configuration, input, or framework guarantee can produce it, classify it as `unreachable in the current implementation` and `reference-only`; do not add it to the current contract solely to mirror the reference. If parity is required, report the implementation change as a prerequisite instead of silently documenting an unreachable behavior.

For example, if a reference declares status `R` but a live request returns HTTP `S` with body `applicationCode: R`, the evidence must contain two findings: reference/documentation status `R`, and observed runtime status `S` with application code `R`. That is not a parity `PASS` unless the accepted contract explicitly permits the difference.

## Verification-lead merge gate

The verification lead owns the evidence collection and merge-readiness recommendation. The user confirms the verification flow and detailed step plan; after approval, the agent executes the checks and reports the result without requiring the user to reproduce each check manually.

Use two objectives in order:

1. **Prove the change works:** derive observable acceptance claims from the Jira issue, approved spec, public contract, and implementation; exercise the required user path and the highest-risk negative path; retain reproducible evidence for each claim.
2. **Reduce functional risk before integration:** inspect the changed diff and proactively verify contract drift, error propagation, compatibility changes, localization, dependency effects, boundary cases, missing regression coverage, and delivery/build differences.

Before execution, create a readiness matrix for every material behavior change:

| Claim | Expected behavior | Implementation path | Verification | Functional risk | Merge consequence |
|---|---|---|---|---|---|
| Concrete behavior being changed | Jira/spec/contract expectation | Files, branch, caller, and consumer | Test or built user-path evidence | Concrete functional risk | `accept`, `fix`, `defer`, or `block` |

Apply this decision rule to the matrix:

```text
block_or_fix =
    reproducible_failure
    OR explicit_requirement_or_contract_violation
    OR concrete_security_data_compatibility_or_delivery_risk

do_not_expand_scope =
    no qualifying risk
    AND the proposed behavior is only stylistic, hypothetical, or unmeasured
```

“Safer,” “cleaner,” “more complete,” “future-proof,” “looks better,” and “no harm” are prompts to identify a measurable risk, not evidence by themselves. Any intentional difference must be recorded with its rationale and boundary before the merge recommendation. Any deferred variant must be labeled `Manual decision required` in the report.

The final report must make the user's decision small: state `PASS`, `CONDITIONAL PASS`, or `FAIL`, list the two or three facts that determine it, identify concrete blockers, and distinguish built user-path evidence from supporting source/test evidence. Do not hand the user a list of commands and ask them to become the verification lead.

## Entry Gate

For an ordinary request to verify something, ask whether to use this workflow. If the user explicitly invokes this skill, treat that as approval to use it. Do not run a command or create a verification script before both confirmation phases below.

## Phase 1: Confirm the Verification Flow

First present a numbered **verification flow**. It defines the verification logic, not an execution plan. State each behavior to prove, its order or dependency, and the observable outcome at a high level. Do not include exact commands, paths, timeouts, status codes, or implementation choices here.

The flow must include, when applicable:

1. Build and establish the delivered artifact under test.
2. Establish the current contract and any authoritative reference artifact.
3. Compare the complete shared public surface and classify differences.
4. Start the delivered artifact and exercise the highest-risk user workflows through public interfaces.
5. Check delivery, isolation, cleanup, deferred details, and merge risks.
6. Produce a claim-level verdict with explicit boundaries and manual-decision items.

End with a direct request for approval of the flow. Revise the flow if the user finds a missing behavior, incorrect order, or invalid assumption. Do not advance until the user approves it.

## Phase 2: Confirm the Step Plan

After the flow is approved, expand **every numbered flow step** into an executable, user-checkable plan. Use one row or subsection per step containing:

| Field | Required content |
|---|---|
| Purpose | The approved flow behavior being proved |
| Setup | Inputs, reference artifacts, build output, user command, isolated runtime layout, and package/module scope |
| Action | Exact command or interaction and its working directory |
| Pass evidence | Concrete response, exit code, process state, artifact, or log condition |
| Fail evidence | What makes the step fail |
| Retained evidence | Script output, raw log, response, directory inventory, or artifact to keep |

Make dependencies explicit: for example, an API probe depends on successful startup; signal handling depends on the started process. Ask the user to approve this detailed plan. Only then create the script and execute it.

For reference-parity work, the plan must contain a comparison step for every shared operation or an explicit reason why it is a deferred detail. Make the dependency on both identified artifacts explicit. The plan must also identify which comparisons are static inspection and which are verified through the built user path.

## Create an Evidence Package

Create a fresh, inspectable evidence root inside the repository's `.codex` directory:

```
.codex/verification-evidence/<timestamp>-<topic>/
```

Keep evidence under this dedicated directory, separate from source, build output, and module runtime data. Do not place evidence in arbitrary tracked files, production directories, or the module tree.

Place these files in it:

```
run.<appropriate-extension>   # fixed, directly runnable verification script
plan.md                       # both approved phases and pass/fail criteria
logs/                         # raw command output, one file per command
workspace/                    # copied built delivery layout and user fixtures
artifacts/                    # copied reference files, responses, diffs, or comparisons
report.md                     # final result; write even on failure
```

Make the script self-describing: capture the current revision, working directory, commands, tool versions, inputs, exit codes, and paths to retained artifacts. Keep its scope narrow; never delete broad paths or mutate the product merely to make verification pass.

For packaging or simulated-user checks, construct `workspace/` from the actual built delivery files. Record the directory tree and every relevant manifest/configuration file. When module resolution, package type, PATH, environment variables, permissions, or current directory can affect behavior, test and record those conditions explicitly. A test that runs only against source files proves only a source-level scenario.

## Claim-level merge gate

Maintain this matrix in `report.md` for each material claim:

| Claim | Sources | Check | Observed result | Verdict | Reader proof | Merge consequence |
|---|---|---|---|---|---|---|
| Concrete statement being made | Implementation, contract, reference, runtime, or test | Reproducible action | Exact result | `PASS`, `FAIL`, or `CONDITIONAL PASS` | Inline explanation/excerpt; optional raw-log/artifact link | Accept, fix, defer, or block |

Use these meanings:

- `PASS`: all applicable lenses for the claim agree and the retained evidence is sufficient to rerun it.
- `CONDITIONAL PASS`: the behavior is acceptable only with a stated intentional difference, unavailable reference, untested environment, parser limitation, or other explicit boundary.
- `FAIL`: evidence contradicts the claim, a required artifact is missing, or a material check was not performed.

Do not claim “matches the reference,” “documentation-only difference,” “runtime compatible,” or “safe to merge” from a passing test command alone. If a material claim cannot be evaluated, mark it unresolved instead of inferring agreement.

## Reader-first report

The report must be understandable without opening a log. Put this decision summary immediately after the verdict:

| Decision item | Required answer |
|---|---|
| Merge decision | `PASS`, `FAIL`, or `CONDITIONAL PASS` in one sentence |
| Why | The two or three facts that determine the decision |
| Must fix before merge | Concrete blocking items, or `None` |
| Manual decision required | Deferred details and the owner/decision needed |
| Evidence confidence | What was proven through the built user path versus static/supporting evidence |

Then present each material finding in this shape:

```markdown
### Finding F-001: short title
**Conclusion:** PASS / FAIL / CONDITIONAL PASS
**Why it matters:** user or merge impact in one sentence.
**Observed:** concise result from the built user workflow.
**Expected/reference:** concise expected result or reference excerpt.
**Decision:** accept, fix, defer, or block.
**Evidence excerpt:** the shortest output excerpt that proves the conclusion.
**Raw evidence:** optional link to the full log/artifact for audit.
```

Inline excerpts and explanations are the primary evidence for readers. Raw-log links are supporting audit trails and must never be the only way to understand a conclusion.

## Report Contract

Write `report.md` with these headings, in this order:

1. **Verdict** - `PASS`, `FAIL`, or `CONDITIONAL PASS`; never use vague success wording.
2. **Decision summary** - the reader-first table above.
3. **Claim and criteria** - exact behavior proved and failure condition.
4. **Approved flow and step plan** - the two approved phases and any approved change.
5. **Reproduction** - evidence-root path, exact script command, working directory, versions, exit code.
6. **Observed evidence** - the claim matrix, reader-first findings, built workspace/artifact inventory, relevant layout/configuration, and concise excerpts from raw logs.
7. **Conditions and boundaries** - assumptions, deferred details marked `Manual decision required`, untested variants, reference limitations, and intentional differences.
8. **Promotion decision** - ask whether the now-proven script/fixture should become a committed pre-submit regression check; do not promote it automatically.

Include a failed command's raw output and preserve the evidence package. Never replace a failure with a guessed fix or a claim that the result is probably correct.

## Evidence Readability

A report must be understandable without asking the reader to infer why a row passed. For **each material claim** in `Observed evidence`, include all of the following immediately adjacent to the claim (or in a clearly keyed table row):

- the concrete result (`PASS`/`FAIL` condition, response, process state, or artifact property);
- an optional direct link to the full raw log, response, or inspected artifact when more context is needed; and
- a short, minimally sufficient excerpt from that raw evidence.

Do not put a collection of generic log links in one place and unrelated excerpts elsewhere. The reader must be able to move directly from a conclusion to its proof.

For negative behavior, retain evidence for both sides of the assertion: for example, a disabled server needs its startup output **and** an unreachable-port probe. For a non-fatal failure, the same evidence item must show the failure signal (error text or exit condition) **and** the continued target-process signal. For an occupied-port scenario, include the occupier's live state as well as the agent's bind-failure log.

A reference mismatch needs both the relevant reference excerpt and the current implementation or runtime excerpt in the same claim row.

If a material claim cannot be backed by retained raw evidence and a concise excerpt, label the verdict `FAIL` or `CONDITIONAL PASS` according to the missing proof; do not call it `PASS`.

## Common Failures

| Bad shortcut | Required correction |
|---|---|
| "The command passed" | Preserve command, cwd, inputs, output, exit code, and inspected artifact. |
| "The tests pass, so the contract matches" | Compare the complete implementation/contract/reference surface and run the built user-path checks. |
| "Only the most visible operation was checked" | Verify every shared operation and classify one-sided items. |
| "The reference YAML is invalid, so ignore it" | Preserve the raw artifact, record the parser limitation, and perform bounded structural comparison. |
| "The screenshot looks the same" | Use the authoritative raw artifact; treat screenshots as supporting context only. |
| "The runtime code and OpenAPI are obviously equivalent" | Inspect both and compare observed behavior through the built public interface. |
| "A single file parses, so the product works" | Build the product and reach the behavior through the user workflow. |
| "The source tree is representative" | Build a clean delivery workspace and record package/configuration scope. |
| "Manual testing covered it" | Script the exact check so another operator can rerun it. |
| "The report has a summary but no proof beside each conclusion" | Link each material conclusion directly to its raw evidence and show a concise supporting excerpt. |
| "Every endpoint/detail must be tested now" | Verify required user paths, list deferred details, and mark them `Manual decision required`. |
| "The high-level flow is enough" | Obtain approval for the detailed, step-by-step plan before execution. |
| "This should become a test now" | Ask only after the evidence run succeeds and the user assesses its value. |
| "It works on my machine" | State the environment and label untested environments as boundaries. |
