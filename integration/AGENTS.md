# Integration Instructions

## Commands

- Run direct `npm` and Node commands from the target `integration/<module-name>/` directory.

## Tests

- Use a temporary directory for test runtime data; do not write it under the module tree.
- Remove each test-created runtime-data directory during teardown.
