# Current Domain Knowledge

## Scope

This directory owns durable knowledge about the system as it exists now: domain concepts, responsibilities, invariants, non-obvious constraints, and cross-component contracts.

Every factual statement in this directory must be directly supported by the current repository build, Schema, source, or automated tests. When a statement conflicts with the executable Schema or tests, the Schema and tests win; correct the affected domain document in the same change.

## Boundaries

- Domain documents describe current behavior. They are not a roadmap and must not present unimplemented ideas as facts.
- Keep user-facing setup, framework configuration, and CLI option examples out of this directory.
- Keep accepted future direction in [`../design/`](../design/index.md), not here.
- Keep detailed implementation mechanics in source and tests unless they are necessary to preserve a cross-component invariant.

## Documents

- [Static Coverage Contract](static-coverage-contract.md): the current Node-to-Java snapshot contract, including input rules, deduplication, source attribution, and static-report interpretation.

## Related Documents

- [Architecture Map](../../ARCHITECTURE.md)
