# javascript-coverage

Gradle multi-module project that builds a single distribution zip containing:
- Java CLI jar: `parasoft-jscov.jar` (built via ShadowJar)
- Integration (Node) module artifacts under `integration/<module>/`
- Placeholder `docs/` and `licenses/` directories
- `EULA.txt` and `settings.properties` at the zip root

## Build

Prerequisites:
- JDK 21 must be available as a local Gradle toolchain (this project uses `java.toolchain.languageVersion = 21`).
  - If you don't have JDK 21 installed, `:javascript-coverage-cli:compileJava` will fail with "Cannot find a Java installation ... languageVersion=21".
- Node is not required for the current skeleton build (integration modules are placeholders), but future integration modules may require it.

Build the distribution artifact:
```powershell
.\gradlew.bat clean dist
```

Run the full test suite:
```powershell
.\gradlew.bat test
```

Output:
- `build/distributions/parasoft_javascript_coverage_1.0.0.zip`

Note:
- Project version is `1.0.0` (see `build.gradle`) and is included in the distribution zip filename.

## Modules

- `:javascript-coverage-cli`
  - Java 21 toolchain, compiled with `--release 17` for runtime compatibility.
  - Produces a single runnable jar named `parasoft-jscov.jar` via the Shadow plugin.

- `:integration`
  - Aggregator for "integration" modules (expected to be Node projects in the future).
  - Does not auto-discover modules; add them explicitly in `settings.gradle`.
  - Node-enabled integration modules contribute a `test` task that is included in the root `test` lifecycle.

- `:integration:parasoft-istanbul-lib-instrument`
  - Fork of `istanbul-lib-instrument` 6.0.3-1 packaged under the `parasoft-istanbul-lib-instrument-6.0.3-1.tgz` artifact name.
  - Produces an npm-compatible tarball with a top-level `package/` directory and the Parasoft package name/version inside `package.json`, while still supporting npm `overrides`.

## Distribution Contents

`parasoft_javascript_coverage_1.0.0.zip` contains:
```text
docs/
licenses/
integration/
  parasoft-istanbul-lib-instrument/
    parasoft-istanbul-lib-instrument-6.0.3-1.tgz
EULA.txt
parasoft-jscov.jar
settings.properties
```

Notes:
- `docs/` and `licenses/` are included as directories (placeholders for now).
- `EULA.txt` and `settings.properties` come from `dist-resources/`.

## Adding A New Integration (Node) Module

1. Add it to `settings.gradle`, for example:
```groovy
include 'integration:my-node-module'
```

2. Create `integration/my-node-module/build.gradle` that publishes one or more artifacts via the
   outgoing configuration `integrationDistElements`.

The root project packages integration module artifacts by resolving:
- `project(path: ':integration:<module>', configuration: 'integrationDistElements')`

So each integration module should publish its final "ship-ready" output(s) to `integrationDistElements`
(this can be a file like `.tgz`/`.zip`, or a directory artifact if you prefer to stage a folder layout directly).
