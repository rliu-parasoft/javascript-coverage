---
kind: agents
---

# Workspace Agent Guidelines

## Project basics
- Language: Java, JavaScript, TypeScript
- Primary build command: `./gradlew build`
- Primary test command: `./gradlew test`

## Code review defaults
- Prioritize correctness, safety, and regression risk over style nits.
- Provide concrete, file-specific recommendations.
- Call out missing tests for behavior changes.
