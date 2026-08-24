---
name: regression-jscov-agent
description: Use when jscov-agent code changes need regression validation against a user-specified AUT JavaScript entry file, including agent.js runtime-data and settings behavior.
---

# jscov-agent Regression

Use this workflow to validate a local `jscov-agent` change against the real AUT that the user identifies.

## Required input

Obtain the AUT JavaScript entry file to test from the user (for example, `server.js`). Do not infer an entry file or substitute another `.js` file. Resolve the supplied path before changing code; if it was not provided or cannot be found, stop and ask the user to check it.

## Workflow

1. Make the requested change in `integration/jscov-agent`.

2. From the Gradle repository root (the directory containing `gradlew`), build the package:

   ```powershell
   .\gradlew integration:jscov-agent:clean integration:jscov-agent:assembleIntegrationDist
   ```

   Use the generated `integration/jscov-agent/build/integrationDist/agent.js`; do not test against source files or an older artifact. If Gradle cannot start because the environment cannot access its cache or lock files, classify that as an environment setup failure and stop until access is available. If the Gradle tasks start and the build fails, stop the workflow.

3. From `integration/jscov-agent`, run the user-specified AUT with the built agent. Choose only the agent options required by the implementation and scenario:

   ```powershell
   node --import ./build/integrationDist/agent.js <aut-entry.js> --jscov.agent.runtimeData ./build/runtimeData --jscov.agent.debug ...
   ```

   `--import` receives a Node ESM module specifier. In PowerShell, keep the preloader spelling exactly as `./build/integrationDist/agent.js`; do not replace it with `./`'s filesystem-style equivalent `.\\build\\integrationDist\\agent.js`.

   Available options include:

   ```text
   --jscov.agent.runtimeData ./build/runtimeData
   --jscov.agent.settings ./build/integrationDist/agent.jsonc
   --jscov.agent.session.autostart=false
   --jscov.agent.restServerEnabled=true
   --jscov.agent.restServerPort 8050
   --jscov.agent.debug
   --jscov.agent.silentMode
   ```

4. When the AUT or agent REST server is long-running, launch it under a retained process handle with redirected stdout and stderr. Choose and report an isolated REST port when the scenario needs one, wait for a requirement-relevant readiness condition with a finite timeout, and always stop only the retained process. Do not terminate a process tree, a child process, or an unknown process that owns a conflicting port. On readiness failure, capture the retained process's logs and report a validation-setup failure.

5. Verify the required behavior through the requirement-specific API behavior, target output, or runtime data. For REST APIs, assert the HTTP status, exact response field set, field values, and any required state transition. Inspect console logs and the log or session files under `--jscov.agent.runtimeData` as supporting evidence when relevant. A successful build, process exit, or file creation alone is not sufficient evidence.

6. If the AUT starts but required behavior does not meet the requirement, return to step 1, correct the implementation, and rerun the complete workflow. If a validation-setup failure prevents the AUT from starting or becoming ready, correct only the harness or request the required environment access, then rerun from the build step. Continue until validation passes or the user asks to stop.

## Report

Report the resolved AUT entry, the built `agent.js` path, selected agent options, selected port when applicable, command outcomes, and concrete behavior evidence. Clearly distinguish a build failure, a validation-setup failure, a run that lacks validation evidence, and a passed regression validation.
