# JavaScript Coverage Architecture

## System Purpose

This repository delivers two related JavaScript/TypeScript coverage capabilities. A **static coverage** toolchain describes coverable structure, not runtime execution: an Istanbul-compatible Node instrumentation package identifies coverable structure during a build, and a Java CLI adapts that structure to Xtest reporting and optional DTP publishing. Separately, a **runtime coverage agent** (`integration/jscov-agent`) preloads into an application-under-test Node process to collect and reset *execution* coverage and expose it over a local REST server.

## Components and Boundaries

| Component | Responsibility | Boundary |
| --- | --- | --- |
| `integration/parasoft-istanbul-lib-instrument` | Instruments source and produces static-coverage snapshots. | Does not generate Xtest/DTP reports or invoke the Java CLI. |
| `javascript-coverage-cli` | Converts snapshots into Xtest static-coverage results. | Does not run Node builds or perform source instrumentation. |
| `integration/jscov-agent` | Preloads into an AUT Node process to collect/reset runtime execution coverage and serve it via a local REST API (sessions, coverage archives, config/info). | Single-user; does not instrument source, produce static snapshots, or run the Java CLI. |
| Xtest and optional DTP | Host reporting and optional publication. | Do not produce the static-coverage snapshots. |

## Primary Data Flow

```text
Application build pipeline
  -> Node instrumentation
  -> static-coverage JSON snapshots
  -> Java CLI / Xtest reporting
  -> optional DTP publication
```

The boundary between the Node package and the Java CLI is the static-coverage JSON snapshot, not an in-process API.

A second, independent flow serves runtime execution coverage: `AUT Node process (agent preloaded) -> REST session start/stop -> per-session runtime coverage JSON under runtimeData -> GET /coverage/{id} ZIP archive`. This flow does not feed the static-coverage JSON snapshot contract.

## Dependency Direction

- The Node instrumentation package does not depend on the Java CLI.
- The Java CLI does not depend on a Node runtime.
- The root Gradle build packages both components as one product distribution and creates no runtime API between them.

## Current Domain Knowledge

Documents in [`docs/domain/`](docs/domain/index.md) own detailed current behavior, domain semantics, and cross-component contracts supported by repository evidence. They describe the current system, not a roadmap.

## Future Architectural Direction

Some accepted future capabilities constrain current architectural boundaries even though they are not yet implemented.

See [`docs/design/index.md`](docs/design/index.md).

Design documents describe intended future direction and **MUST NOT** be treated as descriptions of current system behavior.

## Where to Read Next

Load only the documents your task needs.

| Task or question | Read |
| --- | --- |
| Change static snapshots, source maps, `project` metadata, JSON Schema, function/global line attribution, or multi-worker behavior | [Static Coverage Contract](docs/domain/static-coverage-contract.md) |
| Change the runtime coverage agent: REST routes, session lifecycle, runtime version.json, or agent configuration | [Runtime Coverage Agent](docs/domain/runtime-coverage-agent.md) |
| Propose, evaluate, or implement an accepted future architectural capability | [Future Architectural Direction](docs/design/index.md) |
| Change distribution files, Gradle modules, or publication of a new integration artifact | [`README.md`](README.md) and the relevant `build.gradle` files |
| Change the fork's public instrumentation API or Istanbul behavior | `integration/parasoft-istanbul-lib-instrument/README.md`, `api.md`, source, and specification tests |
