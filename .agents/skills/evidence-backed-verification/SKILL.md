---
name: evidence-backed-verification
description: Use when asked to verify a build, package, artifact, deployment-like layout, startup command, user workflow, signal handling, or integration behavior and the result must be reproducible and defensible in review.
---

# Evidence-Backed Verification

Turn a verification claim into an evidence package another person can inspect and rerun. A passing command alone is not evidence of the conditions under which it passed.

## Entry Gate

For an ordinary request to verify something, ask whether to use this workflow. If the user explicitly invokes this skill, treat that as approval to use it. Do not run a command or create a verification script before both confirmation phases below.

## Phase 1: Confirm the Verification Flow

First present a numbered **verification flow**. It is a logic review, not an execution plan. State each behavior to prove, its order or dependency, and the observable outcome at a high level. Do not include exact commands, paths, timeouts, status codes, or implementation choices here.

For example, a Node agent lifecycle flow may be:

1. Start the agent using the command-line form a user will use.
2. Establish that its server has become available.
3. Exercise the status endpoint to prove the running server responds.
4. Trigger SIGINT and observe shutdown behavior.
5. Preserve the delivery layout, process results, and logs that support every conclusion.

End with a direct request for approval of the flow. Revise the flow if the user finds a missing behavior, incorrect order, or invalid assumption. Do not advance until the user approves it.

## Phase 2: Confirm the Step Plan

After the flow is approved, expand **every numbered flow step** into an executable, user-reviewable plan. Use one row or subsection per step containing:

| Field | Required content |
|---|---|
| Purpose | The approved flow behavior being proved |
| Setup | Inputs, configuration, isolated runtime layout, and relevant package/module scope |
| Action | Exact command or interaction and its working directory |
| Pass evidence | Concrete response, exit code, process state, artifact, or log condition |
| Fail evidence | What makes the step fail |
| Retained evidence | Script output, raw log, response, directory inventory, or artifact to keep |

Make dependencies explicit: for example, an API probe depends on successful startup; signal handling depends on the started process. Ask the user to approve this detailed plan. Only then create the script and execute it.

## Create an Evidence Package

Create a fresh, inspectable evidence root inside the project, normally `.codex/verification-evidence/<timestamp>-<topic>/`. Do not reuse a build directory as the simulated user environment.

Place these files in it:

```
run.<appropriate-extension>   # fixed, directly runnable verification script
plan.md                       # both approved phases and pass/fail criteria
logs/                         # raw command output, one file per command
workspace/                    # copied delivery layout and test fixtures when applicable
report.md                     # final result; write even on failure
```

Make the script self-describing: capture the current directory, commands, tool versions, exit codes, and paths to retained artifacts. Keep its scope narrow; never delete broad paths or mutate the product merely to make verification pass.

For packaging or simulated-user checks, construct `workspace/` from the actual delivered files. Record the directory tree and every relevant manifest/configuration file. When module resolution, package type, PATH, environment variables, permissions, or current directory can affect behavior, test and record those conditions explicitly. A test that runs only inside a build folder proves only that build-folder scenario.

## Report Contract

Write `report.md` with these headings, in this order:

1. **Verdict** - `PASS`, `FAIL`, or `CONDITIONAL PASS`; never use vague success wording.
2. **Claim and criteria** - exact behavior proved and failure condition.
3. **Approved flow and step plan** - the two approved phases and any approved change.
4. **Reproduction** - evidence-root path, exact script command, working directory, versions, exit code.
5. **Observed evidence** - artifact inventory, relevant directory layout/configuration, and concise links or excerpts from raw logs.
6. **Conditions and boundaries** - assumptions, untested variants, and reasons a result is conditional.
7. **Promotion decision** - ask whether the now-proven script/fixture should become a committed pre-submit regression check; do not promote it automatically.

Include a failed command's raw output and preserve the evidence package. Never replace a failure with a guessed fix or a claim that the result is probably correct.

## Review-Readable Evidence

A report must be reviewable without asking the reader to infer why a row passed. For **each material claim** in `Observed evidence`, include all of the following immediately adjacent to the claim (or in a clearly keyed table row):

- the concrete result (`PASS`/`FAIL` condition, response, process state, or artifact property);
- a clickable link to every raw log, response, or inspected artifact needed to substantiate that result; and
- a short, minimally sufficient excerpt from that raw evidence.

Do not put a collection of generic log links in one place and unrelated excerpts elsewhere. The reader must be able to move directly from a conclusion to its proof.

For negative behavior, retain evidence for both sides of the assertion: for example, a disabled server needs its startup output **and** an unreachable-port probe. For a non-fatal failure, the same evidence item must show the failure signal (error text or exit condition) **and** the continued target-process signal. For an occupied-port scenario, include the occupier's live state as well as the agent's bind-failure log.

If a material claim cannot be backed by retained raw evidence and a concise excerpt, label the verdict `FAIL` or `CONDITIONAL PASS` according to the missing proof; do not call it `PASS`.

## Common Failures

| Bad shortcut | Required correction |
|---|---|
| "The command passed" | Preserve command, cwd, inputs, output, exit code, and inspected artifact. |
| "The build directory is representative" | Build a clean delivery workspace and record package/configuration scope. |
| "Manual testing covered it" | Script the exact check so a reviewer can rerun it. |
| "The report has a summary but no proof beside each conclusion" | Link each material conclusion directly to its raw evidence and show a concise supporting excerpt. |
| "The high-level flow is enough" | Obtain approval for the detailed, step-by-step plan before execution. |
| "This should become a test now" | Ask only after the evidence run succeeds and the user reviews its value. |
| "It works on my machine" | State the environment and label untested environments as boundaries. |
