---
name: syncing-docs-from-commits
description: Use when a feature or change set has landed and its code has stabilized, and the user wants project documentation brought in line with a commit range. Triggers include "sync the docs", "update the guide/architecture for these commits", "propose doc changes for this range", or handing over two commits after finishing a piece of work.
---

# Syncing Docs From Commits

## Overview

Turn the changes between two commits into a **reviewed proposal** that brings the project's documentation in line with the current code. You analyze the diff, decide what is worth documenting, reconcile it against what the docs already say (adding, rewriting, or deleting), and present a proposal with evidence. **You never edit the target docs until the user approves.**

**Core principle:** Documentation drift is a correctness bug. A commit range is evidence; the docs are a claim. Where they disagree, propose a change backed by the diff — never by a guess.

**Separation of duties:** *what* belongs in the docs and *how* it is written are governed by the **project's own documentation rules**; this skill only translates a commit range into proposed updates that obey those rules. Discover and follow the rules — never invent or hardcode them.

## Scope

Two *kinds* of documentation surface are in scope; discover where each lives in the current project instead of assuming fixed paths:

1. **User-facing guide(s)** — how someone *uses* the product: prerequisites, setup, configuration, commands/API usage, options, outputs, troubleshooting.
2. **Repo-knowledge / architecture docs** — model-oriented notes that help an agent navigate the system without rescanning all code (e.g. an architecture entry doc plus deeper domain/design notes).

**Discover the targets first.** Do not hardcode paths. Read the project's contributor/agent rules (e.g. `AGENTS.md`, `CONTRIBUTING`, `README`), its architecture entry document, and any docs index to locate the guide(s) and knowledge docs, their boundary conventions, terminology, and style. If you cannot confidently identify a target surface, ask.

**Respect declared out-of-scope areas.** Honor any paths the user or project marks as out of scope (other products, vendored trees, generated code) and exclude them from every diff, search, and proposal. Ask for these boundaries if they are not already established.

## Inputs

- **Required:** a commit range (`<base>..<head>`, or two SHAs).
- **Optional:** in-repo spec/issue notes committed with the range (wherever the project keeps them). Use them to understand intent and what is user-visible; read only those belonging to this range.
- **Not integrated:** external issue trackers. Do not attempt to pull from an issue-tracker server. If the user references an issue, ask them to point you at an in-repo spec/notes file or paste the context.

You gather the diff yourself:

```powershell
git log --oneline <base>..<head>
git diff --stat <base> <head> -- . ":(exclude)<out-of-scope-path>"
git diff <base> <head> -- <path>
```

Always exclude the out-of-scope paths you established (repeat `:(exclude)...` per path). Read specific diffs per path rather than dumping the whole range when it is large.

## Choosing the range

- Prefer a **base** at the commit the docs were last synced to, and a **head** at the stabilized story tip. Choosing an older base re-proposes content the docs already reflect; if you cannot tell where the docs were last synced, ask.
- When the range spans **multiple stories** (many commits/PRs), first present a **grouped overview as a table** (by story/theme, keyed to any spec/issue references) with a column naming the **affected surface(s)** for each group — a user guide, an architecture/knowledge doc, or *out of scope (none)*. Get the user's go-ahead on the grouping before writing detailed edits. Do not emit one giant undifferentiated proposal.

## Evidence sources (read, never edit)

Establish facts from the change and its context: source, tests, the diff, and any authoritative descriptors the project keeps (e.g. API definitions, specs/issue notes, module READMEs). You may also establish a fact with a cheap, read-only command when one settles it directly (see *Uncertainty*); such a command only reads state, it never edits. These are **not** update targets unless one of them *is* a designated documentation surface — do not modify non-target files.

If an evidence source appears **clearly wrong or contradicted by the code** (e.g. a README documents a removed option, an API spec lists a wrong status code), do **not** silently rely on it and do **not** edit it. Record it under **Advisories** in the proposal so the user can decide.

## Follow the project's documentation rules

How content is written and where it belongs are governed by the **project's own documentation rules**, not by this skill. Your job is to find those rules and obey them, not to invent or hardcode your own.

1. **Locate the rules.** Look in the docs index/conventions, the architecture entry doc, and contributor/agent rules (e.g. `AGENTS.md`, `CONTRIBUTING`). Identify where each documentation surface lives and what governs it.
2. **Obey them** for every proposed edit — content ownership per surface, current-vs-future placement, terminology, writing style, evidence/pointer expectations, and how new documents are wired into indexes.
3. **If the rules are missing, ambiguous, or contradictory, stop and ask.** Do not fill the gap with your own convention; a proposal built on an invented rule is not acceptable. Flag the gap so the project can address it.

## Workflow

1. **Collect the range.** Run `git log`/`git diff --stat`, excluding the established out-of-scope paths. Read any in-range spec/issue notes.
2. **Discover and follow the project's documentation rules** and target surfaces if not already known (see Scope and *Follow the project's documentation rules*), then **classify each meaningful change** by surface. Discard out-of-scope and not-worth-documenting changes (see *Which changes to consider*).
3. **Reconcile, don't just append.** For every target doc a change touches, load the doc's **full current content** and compare against the diff. Identify statements the change makes wrong, incomplete, or obsolete. Plan Add / Rewrite / Delete edits — removing or correcting stale text is as important as adding.
4. **Gather evidence** for each proposed edit: the source/test file, commit, or a cheap read-only command + its key output that proves the statement (see *Uncertainty*). Domain statements without repo evidence are not allowed.
5. **Resolve uncertainty by the Uncertainty rule: verify if cheap, otherwise ask — never guess** (see Uncertainty).
6. **Write the proposal** in the output format below. Do not modify any target doc yet.
7. **Wait for approval.** Apply edits only after the user approves, and apply only what was approved. If the user changes something, update the proposal and re-confirm.

## Which changes to consider

Triage the diff to what a reader could act on. Defer *where* content goes and *how deep* it should be to the project's documentation rules.

- **Consider:** behavior, interface, contract, configuration, option, default, output, and error changes.
- **Skip (usually):** pure refactors, internal renames, formatting, dependency bumps with no behavior change, and test-only changes (tests are *evidence for* other statements, not doc entries of their own).
- When unsure whether something is worth documenting, list it under Open Questions rather than adding speculative prose.

## Uncertainty: verify if cheap, otherwise ask — never guess

When a fact you need is not established by the diff, source, in-range specs, or existing docs, you have exactly three moves. Guessing is never one of them.

1. **Verify** when a cheap, safe, read-only check settles the fact directly. Prefer this over asking, so the user does not have to confirm what a command can show. A check qualifies only when ALL of these hold:
   - It is read-only / side-effect-free: it does not write files, mutate state, hit the network, use secrets, or start a service.
   - It uses an existing project command (e.g. a CLI `--help`/`--version`, or printing a computed default), not a build or run pipeline you assemble.
   - It finishes fast and needs no external setup.
   - One or two attempts can settle it; if they do not, stop and ask.
   Record the exact command and its key output as the evidence for any statement it supports.
2. **Ask** when settling the fact would need a full build, the test suite, a regression run, the network/secrets, or any step with side effects — or when a cheap check did not settle it. Heavy validation belongs to the project's dedicated verification/regression skills, not here.
3. **Never guess.** Do not infer runtime behavior by reasoning about what "probably" happens.

**Red flags — stop; verify cheaply or ask, never write it down on a hunch:**
- "It probably behaves like…" / "I'll assume the default is…"
- Documenting an endpoint, option, or message you could not point to in source or specs *and* did not confirm with a cheap read-only command.
- Filling a gap with plausible prose to make a section read completely.
- Being unsure whether behavior is current vs. planned.
- Reaching for a full build or test run to settle a doc detail — that is an Ask, not a Verify.

Anything you cannot settle cheaply becomes an entry in **Open Questions**, not a sentence in the docs.

## Proposal output format

Present the proposal as a report. Do not edit target files in this step.

```
## Doc sync proposal: <base>..<head>

### Summary
- <one line: what changed and which surfaces are affected>

### Changes by file

#### <target file path>
- [Add | Rewrite | Delete] @ <section/anchor or line range>
  - Proposed text:
    > <exact proposed content, or the replacement/deletion>
  - Evidence: <source/test path, commit SHA, or read-only command + key output that proves this>
  - Rationale: <why it clears the worth-documenting bar / what it corrects>

(repeat per edit; group connective edits, e.g. ARCHITECTURE router + docs/domain/index.md, together)

### Open Questions
- <numbered questions the user must answer before those edits can be finalized>

### Advisories (evidence files — not edited)
- <evidence file>: <the apparent error / contradiction with code> — <what the user may want to fix>

### Out of scope / intentionally skipped
- <changes considered but not documented, with a one-line reason>
```

After approval, apply the approved edits with the normal editing tools, then report what was changed.

## Common mistakes

| Mistake | Fix |
| --- | --- |
| Appending new text while leaving contradicted statements in place | Reconcile against full current doc; propose Rewrite/Delete for stale content. |
| Inventing a documentation rule the project has not stated | Follow the project's rules; if they are missing or unclear, stop and ask. |
| Leaving indexes/cross-references stale after adding or removing a doc | Update whatever points to it, per the project's conventions. |
| Guessing runtime behavior or an option default | Verify with a cheap read-only command when one exists; otherwise move it to Open Questions and ask. |
| Running a full build, test suite, or regression to settle a doc detail | That is an Ask, not a Verify; leave heavy validation to the project's dedicated verification/regression skills. |
| Touching declared out-of-scope areas | Exclude out-of-scope paths from every diff and proposal, always. |
| Editing an evidence file (README/spec/API def) to fix an error | Never edit non-target files; report it under Advisories. |
| One giant proposal for a multi-story range | Give a grouped overview first, confirm grouping, then detail. |
| Applying edits before approval | Proposal only; edit after the user approves. |
