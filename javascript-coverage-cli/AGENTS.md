# Java Module Rules

## Development Conventions
1. **Gradle Commands Must Run From Repository Root**:
   - **When**: Running Gradle tasks for Java modules
   - **Do**: Execute from repository root: `./gradlew :javascript-coverage-cli:build`
   - **Why**: Multi-module Gradle build; wrapper doesn't support sub-directory execution
