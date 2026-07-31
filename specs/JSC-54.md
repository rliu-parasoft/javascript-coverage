---
status: READY
status_reason: "The environment-variable semantics, affected integration paths, runtime behavior, and test strategy have been reviewed and approved."
open_questions_count: 0
source_issue_key: JSC-54
---

# Spec Draft: JSC-54

## Source
- Issue Key: JSC-54
- Title: Support using an environment variable to control the generation of static coverage .json files
- Description:
  - Currently, because the original `istanbul-lib-instrument` library is overridden with `parasoft-istanbul-lib-instrument`, using `istanbul-lib-instrument` outside the build process (for example, while collecting unit-test coverage) has the side effect of creating the `.parasoft/static-coverage/{pid}` directory and generating `{fileName}-{uuid}.json` files within it.
  - Use an environment variable to control whether these files are generated.
  - Environment variable: `PARASOFT_STATIC_COVERAGE_ENABLE=true`
  - Default value: `false`. Users can enable it before running the build process.

## Goal
Allow users to opt in to static coverage JSON generation with `PARASOFT_STATIC_COVERAGE_ENABLE`, while keeping generation disabled by default and avoiding static-coverage work when disabled.

## In Scope
- Gate generation of `.parasoft/static-coverage/{pid}/{fileName}-{uuid}.json` files on `PARASOFT_STATIC_COVERAGE_ENABLE`.
- Include the static-coverage integration flow across `src/static-coverage.js`, `src/project-path-mapper.js`, and both relevant `src/visitor.js` call sites. (inferred)
- Keep static coverage JSON generation disabled when the environment variable is absent.
- Allow users to enable generation by setting `PARASOFT_STATIC_COVERAGE_ENABLE=true` before the build process.
- Add automated coverage for the enabled and default-disabled behavior. (inferred)

## Out of Scope
- Not explicitly defined in Jira.

## Behavior
- `visitor.js` compares `PARASOFT_STATIC_COVERAGE_ENABLE` with `true` case-insensitively once when `visitor.js` is first loaded.
- When `PARASOFT_STATIC_COVERAGE_ENABLE=true` is set before `visitor.js` is first loaded, project mapping and static coverage JSON generation are enabled.
- When the environment variable is absent or has any value other than `true` in any letter case, `visitor.js` skips both existing `writeStaticCoverage` call sites while project mapping retains its normal behavior.
- When generation is disabled, the `.parasoft/static-coverage/{pid}` directory and its generated JSON files are not created as a side effect of using the instrumentation library. (inferred)
- When generation is enabled, file naming, JSON contents, source-map remapping, duplicate-file handling, and existing filesystem error behavior remain unchanged. (inferred)

## Architecture and Data Flow (inferred)
- `src/visitor.js` is the feature gate and captures the environment value once at module load.
- `src/visitor.js` returns before project mapping at both static-coverage write call sites, preventing unnecessary mapping, remapping, directory creation, and file writes when disabled.
- `src/project-path-mapper.js` remains an environment-independent project metadata utility.
- `src/static-coverage.js` remains responsible for the existing output format and write algorithm; it is not invoked by the visitor when the feature is disabled.

## Testing Strategy (inferred)
- Test case-insensitive `true`, absent, and non-`true` visitor behavior, with the value captured at visitor module load.
- Test that environment changes after visitor module load do not change the captured behavior.
- Test instrumentation with the flag disabled to verify no static-coverage output is created.
- Test instrumentation with the flag enabled to verify the expected JSON output is still created.
- Test the enabled static-coverage path for files marked `istanbul ignore file`.
- Preserve existing static-coverage writer tests for output naming, content, remapping, duplicate handling, and directory creation.
- Isolate environment-snapshot cases with separate module cache contexts or child processes.

## Edge Cases (Optional)
- Values other than case-insensitive `true` keep generation disabled. (inferred)
- Changes to the environment variable after module load do not affect the current process. (inferred)

## Done When (Acceptance Criteria)
- [x] `PARASOFT_STATIC_COVERAGE_ENABLE=true` enables generation of the static coverage JSON files.
- [x] The default value is `false`, so generation is disabled when the variable is not set.
- [x] Using the overridden instrumentation library outside the build process no longer creates static coverage output unless explicitly enabled. (inferred)
- [x] Automated tests cover the default-disabled and explicitly-enabled paths. (inferred)

## Clarifications

### Assumptions
- [A1] The flag should control the existing static coverage output path without changing the JSON file format or naming scheme. **Resolved:** Keep the existing format, naming, remapping, duplicate handling, and write behavior when enabled.
- [A2] The flag is read from the process environment by the JavaScript instrumentation package. **Resolved:** Read it from `process.env` when `visitor.js` loads.

### Unclear Points
- [U1] Jira does not define whether only the value `true` enables generation case-insensitively or whether values such as `1` or `yes` should also enable it. **Resolved:** Any letter case of `true` enables generation; other values remain disabled.
- [U2] Jira does not identify whether the change belongs in `parasoft-istanbul-lib-instrument`, a wrapper, or another integration module. **Resolved:** Use the existing `parasoft-istanbul-lib-instrument` flow, with the feature gate in `src/visitor.js`, the environment-independent `src/project-path-mapper.js` utility, and `src/static-coverage.js` unchanged.

### Missing Info
- [M1] The expected behavior when `PARASOFT_STATIC_COVERAGE_ENABLE` is changed after the relevant module is loaded is not stated. **Resolved:** The value is evaluated once when `visitor.js` loads; later environment changes do not affect static coverage generation in that process.

### Questions for Human
- [Q1] (re [U1]) Should generation accept any capitalization of `true`, or should common truthy values such as `1` and `yes` also be accepted? **Answered:** Any letter case of `true` enables generation; other values remain disabled.
- [Q2] (re [U2]) Should the implementation be limited to the package/module that creates `.parasoft/static-coverage`, with callers left unchanged (recommended)? **Answered:** Do not limit the change to `src/static-coverage.js`; put the gate in `src/visitor.js`, keep `src/project-path-mapper.js` environment-independent, and preserve the relevant visitor call sites.
- [Q3] (re [M1]) Should the value be evaluated once when the module loads (recommended), or re-evaluated for each generation attempt? **Answered:** Evaluate it once when `visitor.js` loads.

### Risks
- [R1] (re [U1]) Inconsistent parsing could enable output unexpectedly in user environments and undermine the default-off requirement. **Mitigation:** Use a case-insensitive comparison with `true` and test non-`true` values.
- [R2] (re [U2]) Changing the wrong integration boundary could leave the out-of-build side effect intact or affect unrelated coverage behavior. **Mitigation:** Gate both existing visitor write call sites while preserving the writer’s enabled behavior and adding end-to-end instrumentation tests.
