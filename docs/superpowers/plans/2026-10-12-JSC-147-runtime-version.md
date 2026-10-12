# Runtime Coverage Schema Version Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Read the runtime root manifest before discovering coverage JSON files.

**Architecture:** Extract common manifest JSON validation into a package-private helper. Preserve the static reader API, add a distinct runtime schema enum and reader, and expose a versioned runtime-file discovery record. The existing CLI runtime-reporting stubs are outside this foundational task.

**Tech Stack:** Java 17-compatible source, Java 21 toolchain, Jackson, JUnit 5, existing NLS resources, root Gradle wrapper.

**Spec:** `specs/JSC-147.md`

## Global Constraints

- Implementation stays in `javascript-coverage`; source changes are confined to `javascript-coverage-cli`.
- Run Gradle through the repository-root wrapper; run only the affected Java CLI module tests.
- English and Chinese messages use i18n resources; tests derive message expectations from those resources.
- Test paths use `@TempDir` and `Path.resolve`; separate adjacent test cases with one blank line.
- Add no dependencies and preserve existing static reader behavior.

### Task 1: Runtime Manifest Validation and Ordered File Discovery

**Files:**
- Create `javascript-coverage-cli/src/main/java/com/parasoft/jscov/coverage/CoverageVersionManifestReader.java` for shared JSON validation.
- Modify `javascript-coverage-cli/src/main/java/com/parasoft/jscov/coverage/StaticCoverageVersionManifestReader.java` to delegate shared validation while preserving its API.
- Create `javascript-coverage-cli/src/main/java/com/parasoft/jscov/coverage/RuntimeCoverageSchemaVersion.java` and `RuntimeCoverageVersionManifestReader.java`.
- Create `javascript-coverage-cli/src/main/java/com/parasoft/jscov/coverage/RuntimeCoverageFiles.java` for manifest-first discovery.
- Modify `javascript-coverage-cli/src/main/java/com/parasoft/jscov/i18n/CommonMessages.java` and both `src/main/resources/com/parasoft/jscov/i18n/res/messages*.properties` files.
- Add tests beside the existing coverage reader tests. Modify static tests only where shared resource names require it.

**Interfaces:**
- Preserve `StaticCoverageVersionManifestReader.read(Path): StaticCoverageSchemaVersion throws IOException`.
- Produce `RuntimeCoverageVersionManifestReader.read(Path): RuntimeCoverageSchemaVersion throws IOException`.
- Produce `RuntimeCoverageFiles.read(Path): RuntimeCoverageFiles throws IOException` with `schemaVersion()` and `jsonFiles()` accessors.
- `RuntimeCoverageSchemaVersion.V1_0` maps exactly to `"1.0"`; static and runtime schemas remain separate types.

- [x] **Step 1: Write behavioral tests and observe failure.**

Use a real temporary runtime root and manifest. Assert reader/discovery outcomes, not implementation text or mock behavior. Test valid manifest and unknown fields; missing and directory-valued manifests; invalid JSON with preserved cause; empty/array/scalar roots; missing, null, blank, and non-string values of each required field; unsupported schema; nested session paths; manifest exclusion; an empty root; and root-only version selection. Demonstrate manifest-first ordering by calling discovery for a nonexistent root and asserting the localized missing-manifest exception rather than a directory traversal failure.

```java
@Test
void read_validatesManifestBeforeEnumeratingFiles() {
    Path missingRoot = tempDir.resolve("missing-root");
    IOException failure = assertThrows(IOException.class,
            () -> RuntimeCoverageFiles.read(missingRoot));
    assertEquals(NLS.getFormatted(CommonMessages.MISSING_RUNTIME_COVERAGE_VERSION_MANIFEST),
            failure.getMessage());
}
```

Run `./gradlew :javascript-coverage-cli:test --tests '*RuntimeCoverage*'`; before new APIs exist, record the expected compilation failure, then rerun after minimal API scaffolding to observe behavioral failures before implementation.

- [x] **Step 2: Implement shared validation and runtime discovery.**

Extract the existing `Files.readString`/Jackson parsing/required-field validation into the helper. Supply coverage-specific message keys to keep missing/unreadable/invalid messages accurate; use shared object/field validation messages. The typed readers perform their own schema support checks. Preserve causes when wrapping I/O and JSON parsing failures.

```java
public record RuntimeCoverageFiles(RuntimeCoverageSchemaVersion schemaVersion, List<Path> jsonFiles) {
    public static RuntimeCoverageFiles read(Path runtimeDataDirectory) throws IOException {
        RuntimeCoverageSchemaVersion version = RuntimeCoverageVersionManifestReader.read(runtimeDataDirectory);
        try (var paths = Files.walk(runtimeDataDirectory)) {
            List<Path> files = paths.filter(Files::isRegularFile)
                    .filter(path -> path.getFileName().toString().endsWith(".json"))
                    .filter(path -> !path.getFileName().toString().equals("version.json"))
                    .sorted().toList();
            return new RuntimeCoverageFiles(version, files);
        }
    }
}
```

Wrap initial and lazy traversal I/O errors in localized `IOException`s if adding the discovery-specific diagnostic. No runtime report parsing or changes to the runtime option guard.

- [x] **Step 3: Verify the focused tests and static regressions.**

Run `./gradlew :javascript-coverage-cli:test --tests '*RuntimeCoverage*' --tests '*StaticCoverageVersionManifestReaderTest' --tests '*StaticCoverageParserTest'`. Confirm resource-derived diagnostics and exception causes. Inspect static behavior against its existing tests.

- [x] **Step 4: Run the complete affected module suite and commit.**

Run `./gradlew :javascript-coverage-cli:test`, inspect test reports, and run `git diff --check`. Commit only task-related source, tests, spec, and plan. Write RED/GREEN evidence and exact commands/results to the implementer report; controller performs independent reviews.
