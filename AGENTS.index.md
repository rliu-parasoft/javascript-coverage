# AGENTS Rule Index

## Purpose
Defines scope-based routing for additional AGENTS files.

## Always-Load Files
- `AGENTS.common.md`

## Scope Routes
- **JavaScript work** → `integration/AGENTS.md`
- **Java work** → `javascript-coverage-cli/AGENTS.md`
- **Mixed work** → Load both

## Scope Triggers
- **JavaScript**: Changes to JS/TS source, Node.js code, or JavaScript tooling
- **Java**: Changes to Java source, JVM backend, or Gradle configuration
- **Mixed**: Changes involving both languages

## Precedence
When multiple AGENTS files apply, nearest/deepest file overrides parent rules.
