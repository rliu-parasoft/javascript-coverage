# Static Coverage Contract

## Scope

This document defines the repository-internal contract between static-coverage snapshots written by `parasoft-istanbul-lib-instrument` and the Java CLI that reads and interprets them. It does not replace the JSON Schema or describe the complete Istanbul instrumentation API.

The authoritative field constraints are in [`static-istanbul-coverage.schema.json`](../../javascript-coverage-cli/src/main/resources/com/parasoft/jscov/coverage/istanbul/static-istanbul-coverage.schema.json).

## Core Concepts

| Concept | Meaning |
| --- | --- |
| Static snapshot | An Istanbul file-coverage structure frozen during instrumentation, with optional `project` metadata. It identifies statement, function, and branch locations; it does not mean the source code has executed. |
| Process output directory | The `.parasoft/static-coverage/<pid>/` directory written by one Node process. It contains that process's `version.json` manifest and static-coverage JSON files. |
| Project metadata | `{ name, root }`, derived by the writer from the nearest `package.json` for the source file within the current working directory. It determines the project and resource-path attributes that the CLI gives to Xtest. |
| Coverable line | A line inferred by the Java CLI from a statement's start line in `statementMap`. The CLI does not use the counters in `s`, `f`, or `b` to decide whether to report that line. |
| `<global>` | The synthetic block for coverable statements that are not inside a function body. It is report semantics, not a source-code function. |

## Producer Responsibilities

- The writer produces snapshots only when `PARASOFT_STATIC_COVERAGE_ENABLE` equals `true` (case-insensitively), evaluated once before the Node visitor loads. Any other value — for example an absent variable, `false`, `1`, `yes`, or an empty string — disables generation, and changing the environment after loading has no effect.
- When enabled, the writer creates one process output directory below `.parasoft/static-coverage/` in the current working directory. Before writing any snapshot, it creates that directory's `version.json` manifest with string `schemaVersion` (`1.0`) and `toolVersion` fields. One writer process preserves only the first snapshot it writes for the same source path.
- Each output filename is `<source-file-basename>-<UUIDv5-of-the-full-source-path>.json`. This name helps trace a file but is not a unique business key for the Java CLI.
- When input coverage data includes a source map, the writer attempts to map the snapshot to original source files; one input may produce several source-file snapshots. If mapping fails, the writer retains unmapped data rather than stopping instrumentation.
- Project discovery does not traverse above the Node process's current working directory. Without a usable `package.json`, it uses the working directory's basename and path; a malformed package file or a non-string/missing `name` produces the name `unknown`.

## Consumer Responsibilities

- `-app` must name a directory. The CLI scans the directory's immediate child directories as process output directories. Before validating and deserializing direct coverage JSON files, it reads the directory's `version.json`.
- A version manifest must be a JSON object with non-blank string `schemaVersion` and `toolVersion` fields; additional fields are allowed. An absent, unreadable, malformed, or unsupported manifest causes that directory to be skipped.
- The Schema requires top-level `path`, `statementMap`, `fnMap`, `branchMap`, `s`, `f`, and `b`; unknown additional fields are allowed. `project` may be absent or `null`.
- An unreadable or invalid individual snapshot is skipped and reported. Scanning fails when the directory contains no JSON, or when every JSON snapshot is invalid.
- The CLI deduplicates by **snapshot filename**, not by the JSON `path`, and never merges coverage content. Across accepted process output directories, it keeps the file with the highest supported `schemaVersion`; for equal schema versions, sorted process output directory and filename order makes the first file win. `toolVersion` is validated but does not affect selection.
- For each source file, the CLI builds the static hierarchy `file -> function / <global> -> line`. Function attribution uses the Istanbul function-body range, `fnMap[*].loc`, rather than the declaration range, `decl`. A statement that cannot be reliably attributed but has a start line belongs to `<global>`; a statement with no start line produces no line.
- When `project.name` is present, the CLI creates Xtest `projId`, `project`, and `projPath` attributes. If `project.root` contains the source file, `resProjPath` is relative to that root. Missing metadata becomes `unknown`; a path that cannot be relativized remains the original path with `/` separators.

## Important Distinctions

### Static Structure, Not Runtime Execution

Istanbul's `s`, `f`, and `b` counters remain part of the snapshot because the Schema is compatible with Istanbul file coverage. The current Java CLI uses them to validate the input shape, but constructs report content from location mappings. Do not change static coverable lines by changing counters, and do not connect this input to a runtime-coverage flow.

### Permitted Incomplete Location Information

Real Istanbul data may contain `end.column: null`. The Schema and function-attribution logic allow this: when line boundaries are sufficient to determine containment, an unknown column does not exclude a statement. Conversely, when required line boundaries are absent, the CLI does not guess function attribution.

### Artifact Deduplication, Not Coverage Merging

The writer's “first write wins” behavior applies only within one `<pid>` directory. The reader's version-aware, same-filename selection is also not cross-process data merging: it retains one artifact according to schema-version priority and sorted order. Before parallel builds or snapshot aggregation, decide which snapshot is authoritative rather than relying on deduplication to merge results.

## Change Invariants

- Evolve the writer format, Java Schema, Java reader, and cross-language tests together. Changing one side alone defers failure to the user's reporting stage.
- A change to `project` discovery or path normalization must preserve the “nearest in-workspace `package.json`” and “still report when no project can be inferred” boundaries, or explicitly redefine and test them.
- A change to function attribution must cover `<global>`, nested or adjacent functions, same-line column boundaries, and `null` column information. Those rules determine the report structure displayed by DTP/Xtest.
- Runtime coverage, report merging, and `-include`/`-exclude` are not current extension points of this contract; the Java engine explicitly rejects them.

## Related Components

- Writer: `integration/parasoft-istanbul-lib-instrument/src/visitor.js`, `static-coverage.js`, and `project-path-mapper.js`
- Format authority: `javascript-coverage-cli/src/main/resources/.../static-istanbul-coverage.schema.json`
- Reader and interpretation: `javascript-coverage-cli/src/main/java/com/parasoft/jscov/coverage/`
- Behavior evidence: `static-coverage*`, `StaticCoverageParser*`, `IstanbulJsonCoverageReader*`, and `IstanbulFunctionLineMapper*` tests in the two modules

## Related Documents

- [Architecture Map](../../ARCHITECTURE.md)
- [Current Domain Knowledge](index.md)
