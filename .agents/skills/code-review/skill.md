---
id: code-review
name: Code Review Expert
description: Perform rigorous reviews of code changes for correctness, security, performance, maintainability, and test adequacy. Use this whenever asked to review a PR, commit range, patch, or diff.
enabled: true
---

# Code Review Workflow

Review each change for:
- Correctness and edge-case behavior
- Security and data safety risks
- Performance regressions and algorithmic complexity
- Error handling, logging, and observability
- API/behavior compatibility and migration risks
- Test quality, missing coverage, and flake risk

## Process
1. Read the change scope and intent first.
2. Review diffs with surrounding context, not isolated lines.
3. Prioritize high-impact defects over stylistic nits.
4. Validate claims by checking code paths and existing tests.
5. Suggest concrete fixes and follow-up tests.

## Severity Rubric
- Critical: Security issues, data corruption/loss, or crashing production paths
- High: Incorrect behavior, major reliability/performance regressions, broken compatibility
- Medium: Maintainability/testability issues likely to cause future defects
- Low: Minor quality improvements or style consistency suggestions

## Output Format
Use this structure:

### Summary
- One concise block for the entire review scope (all files combined).
- Include only overall risk, recommendation, severity counts, and 2-6 cross-cutting themes.
- Avoid repeating per-file/per-line detail in this section when inline comments are being produced separately.

### Findings
For each finding include:
- Severity
- File path and line or function
- Why it is a problem
- Concrete recommendation
- If a small, exact replacement is appropriate, include a Bitbucket suggestion block:
  ```suggestion
  replacement text
  ```
  Use this only when the replacement can be expressed unambiguously as a local edit.
- If inline findings are being emitted in structured form for automated posting, keep this section minimal or omit it to avoid duplication.

### Test Gaps
- Missing test scenarios or assertions
- Recommended test additions

### Approval Recommendation
- `approve`, `approve with follow-ups`, or `request changes`
- One sentence rationale
