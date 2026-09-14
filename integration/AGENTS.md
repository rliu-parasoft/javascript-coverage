# Integration Instructions

## Commands

- Run direct `npm` and Node commands from the target `integration/<module-name>/` directory.

## Tests

- Use a temporary directory for test runtime data; do not write it under the module tree.
- Remove each test-created runtime-data directory during teardown.

## Type Checking

- Run `npm exec -- tsc --noEmit` from the target Node module after changing TypeScript source or tests.

## Localized Diagnostics

- When an HTTP response and the agent file log use the same message, use one key without the `_diagnostic` suffix. That message must omit filesystem paths and raw underlying errors unless required by the API contract.
- Use a `*_diagnostic` key only for a more detailed message written exclusively to the agent file log. It may include filesystem paths and underlying error details.
- When the file log needs extra context, use separate public and diagnostic keys.

## OpenAPI

- When adding or modifying a REST route in `integration/jscov-agent/src/server/` or changing its HTTP behavior, update the synchronized `integration/jscov-agent/openapi.yml` contract in the same change.
- Keep the definition aligned with the route methods, paths, path parameters, response status codes, response schemas, binary downloads, and the established 405 missing-version-file contract.
