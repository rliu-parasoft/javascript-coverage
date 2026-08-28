# Integration Instructions

## Commands

- Run direct `npm` and Node commands from the target `integration/<module-name>/` directory.

## Tests

- Use a temporary directory for test runtime data; do not write it under the module tree.
- Remove each test-created runtime-data directory during teardown.

## Type Checking

- Run `npm exec -- tsc --noEmit` from the target Node module after changing TypeScript source or tests.
