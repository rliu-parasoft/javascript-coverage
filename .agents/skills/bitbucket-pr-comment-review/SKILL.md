---
name: bitbucket-pr-comment-review
description: Evaluate Bitbucket pull request comments and decide whether code changes are needed. Use this whenever the user shares a Bitbucket PR URL, asks to assess reviewer comments, asks whether a comment is valid, or asks for follow-up fixes from PR feedback. If no PR URL is supplied, attempt to discover it from Bitbucket for the current branch.
---

# Bitbucket PR Comment Review

## Goal
Read review comments on a Bitbucket pull request, verify technical validity against the current code and tests, and recommend or implement changes when appropriate.

## Inputs
- Preferred: explicit Bitbucket PR URL from the user.
- Fallback: no PR URL provided -> discover PR for current branch from Bitbucket.

## Required credentials
- Use `BITBUCKET_TOKEN` for authentication.
- If `BITBUCKET_TOKEN` is not set, accept `BITBUCKET_PAT`.
- Use `BITBUCKET_USER` for the username.
- If `BITBUCKET_USER` is not set, accept `BITUBCKET_USER` (common typo).
- If neither is set, derive username with `id -un` and continue.
- Never print or echo the token value.

## Workflow
1. Resolve the PR URL:
   - If user supplied a URL, use it.
   - If no URL was supplied:
     - run `scripts/discover-pr-url.sh`
     - the script detects current branch, parses `origin`, queries open PRs, and selects the matching source branch PR
   - If zero matches: report that no open PR was found for the branch and ask for a URL.
   - If multiple matches: list candidates and ask user which PR to review.
2. Parse the resolved PR URL to extract `project`, `repo`, and `pull request id`.
3. Fetch PR activities:
   - run `scripts/fetch-pr-activities.sh "<pr-url>"` (or run without args to auto-discover URL first)
   - underlying API call: `GET /rest/api/latest/projects/{project}/repos/{repo}/pull-requests/{id}/activities?limit=200`
4. Extract unresolved review comments only (ignore already resolved comments):
   - run `scripts/fetch-pr-activities.sh "<pr-url>" | scripts/extract-unresolved-comments.sh`
   - filter rule: treat `comment.threadResolved == true` as resolved, then include comments whose effective state is not `RESOLVED`
   - effective state rule: use `comment.state` when present; if missing and `threadResolved == true`, treat as `RESOLVED`; otherwise treat as `OPEN`
5. Group remaining review comments by:
   - comment id
   - author
   - severity language (if present)
   - technical claim
6. For each claim, inspect the referenced code paths and nearby tests before deciding.
7. Classify each comment:
   - `valid`
   - `partially valid`
   - `not supported by code evidence`
8. Provide a concise recommendation for each:
   - accept and patch
   - accept with constraints
   - reject with rationale
9. If changes are requested or clearly needed:
   - implement minimal, targeted edits
   - add or adjust tests
   - run focused tests
10. Report outcome with file-level evidence.

## Output format
Use this exact structure:

### PR comment assessment
- Comment: <comment id>: <short quote or summary>
- Verdict: <valid | partially valid | not supported>
- Evidence: <file paths and key behavior>
- Recommendation: <accept/reject/partial and why>

### Proposed changes
- <bullets of concrete code/test updates, or "none">

### Validation
- Commands run
- Test results

## Command guidance
- Prefer reproducible scripts in `scripts/` over ad-hoc one-liners:
  - `scripts/discover-pr-url.sh [branch]`
  - `scripts/fetch-pr-activities.sh [pr-url]`
  - `scripts/extract-unresolved-comments.sh [activities-json-file]`
- Script behavior:
  - `discover-pr-url.sh` exits non-zero for zero or multiple branch matches and prints diagnostics.
  - `fetch-pr-activities.sh` accepts optional `BITBUCKET_ACTIVITY_LIMIT` (default `200`).
  - `extract-unresolved-comments.sh` removes comments that are effectively resolved (`state == "RESOLVED"` or `threadResolved == true` when `state` is missing) and outputs structured unresolved comments.
  - `reply-pr-comment.sh` accepts `--text`/`--text-file` as optional; provide either to add a reply, or omit both and pass `--resolve` for resolve-only operation.
  - `reply-pr-comment.sh --resolve` sets `state: "RESOLVED"` and `threadResolved: true`, then verifies the parent thread remains effectively resolved via a follow-up GET.
- The scripts rely on `git`, `curl`, `jq`, and `base64`.
- Use repository-local evidence first (source + tests), not assumptions.
- If auth fails, ask the user to export missing env vars and retry.

## Notes
- Keep analysis technical and objective.
- Do not agree performatively with reviewers; verify first.
- When evidence is incomplete, say what is missing and what check is required next.
