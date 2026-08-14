---
name: regression-parasoft-istanbul-lib-instrument
description: Build and run regression validation for local changes to the Parasoft fork of istanbul-lib-instrument. Use when code in parasoft-istanbul-lib-instrument has changed and needs validation, or when the user requests regression validation, with a user-specified target npm project.
---

# Parasoft Istanbul Instrument Regression

Use this workflow to validate a local change through the target project's real build-time instrumentation.

## Required input

Obtain the target project's root directory from the user. Do not guess it. Before deleting anything, resolve the directory and state that only its `node_modules`, `.parasoft`, and `package-lock.json` will be removed.

## Workflow

1. Make the requested code change in `parasoft-istanbul-lib-instrument`.

2. From the Gradle repository root (the directory containing `gradlew`), build the package:

   ```powershell
   .\gradlew integration:parasoft-istanbul-lib-instrument:integrationTgz
   ```

   Stop on a failed build. Locate the generated `parasoft-istanbul-lib-instrument-*.tgz`; use its absolute path for the next step. Do not assume the versioned filename is always `6.0.3-1`.

3. Edit the target project's `package.json`. Ensure it contains an `overrides` entry whose `istanbul-lib-instrument` value is a `file:` dependency pointing to the generated tgz. The path may be either absolute or relative to the target project; use whichever valid path the target project requires:

   ```json
   {
     "overrides": {
       "istanbul-lib-instrument": "file:../vendor/parasoft/istanbul-lib-instrument/parasoft-istanbul-lib-instrument-6.0.3-1.tgz"
     }
   }
   ```

   If `overrides` already exists, preserve its unrelated entries. If `istanbul-lib-instrument` already exists, replace only its value with the path to the newly built tgz. Confirm the selected tgz path exists before proceeding.

4. From the resolved target-project root, remove only the stale local install artifacts, then reinstall and build:

   ```powershell
   Remove-Item -Recurse -Force -LiteralPath node_modules, .parasoft -ErrorAction SilentlyContinue
   Remove-Item -Force -LiteralPath package-lock.json -ErrorAction SilentlyContinue
   npm install
   $env:DEBUG = "parasoft-istanbul-lib-instrument"
   npm run build
   ```

   Stop if either npm command fails. Do not delete any other project files.

5. Verify the change in the build artifacts produced by the target project. Inspect the output that exercises the modified instrumentation behavior, and report the concrete evidence (for example, an expected transformed construct, metadata, or changed output). A successful build alone does not prove the code change took effect.

   If the package build, target-project build, or artifact validation fails, return to step 1, modify the implementation to address the failure, and rerun the complete workflow until validation passes or the user directs otherwise.

## Report

Report the tgz path used, the target project, whether the override was added or updated, command outcomes, and the artifact evidence. Clearly distinguish a failed build, a build that succeeded without evidence, and a validated regression run.
