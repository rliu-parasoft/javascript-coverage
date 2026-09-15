# Parasoft JavaScript Coverage User Guide

## Prerequisites
- Node.js 22+
- Java 21+
- parasoft-istanbul-lib-instrument 6.0.3-1

## Static Coverage

This section describes the static coverage workflow for JavaScript and TypeScript project builds. It covers build-time instrumentation, coverage data generation, creation of a Xtest-compatible XML report, and optional publication of the report and source code to DTP.

### 1. Configure build integration

#### 1.1 Supported frameworks

The following build tools and framework combinations are grouped by the instrumentation plugin used. Each group distinguishes verified integrations from integrations that are theoretically supported but have not been verified yet.

##### Supported build tools

- Projects whose code-transformation pipeline passes through `@babel/core` can theoretically use `babel-plugin-istanbul`.
  - Verified integrations:
    - Babel CLI (`@babel/cli`)
    - Webpack + `babel-loader`
    - CRA (Create React App)
    - Next.js (Babel mode)
  - Not yet verified integrations:
    - Metro (React Native)
    - Rollup + `@rollup/plugin-babel`
    - Parcel + Babel configuration  


- Projects whose source is processed by the Vite plugin transform pipeline can theoretically use `vite-plugin-istanbul`.
  - Verified integrations:
    - React + Vite
  - Not yet verified integrations:
    - Preact + Vite
    - Vue 3 + Vite
    - Svelte + Vite
    - SolidJS + Vite
    - Lit + Vite
    - Vanilla JS + Vite

### 2. Replace `istanbul-lib-instrument` package

Use the configuration for the package manager used by the project. The examples below replace the `istanbul-lib-instrument` dependency with the Parasoft package archive.

#### 2.1 npm

For npm projects, add the `overrides` field to the root `package.json`:

```json
{
  "overrides": {
    "istanbul-lib-instrument": "file:path/to/parasoft-istanbul-lib-instrument-6.0.3-1.tgz"
  }
}
```

#### 2.2 pnpm

For pnpm projects, add the override to the root `package.json` under `pnpm.overrides`:

```json
{
  "pnpm": {
    "overrides": {
      "istanbul-lib-instrument": "file:path/to/parasoft-istanbul-lib-instrument-6.0.3-1.tgz"
    }
  }
}
```

#### 2.3 Yarn Berry

For Yarn Berry projects, add the resolution to the root `package.json` under `resolutions`:

```json
{
  "resolutions": {
    "istanbul-lib-instrument": "file:vendor/parasoft-istanbul-lib-instrument-6.0.3-1.tgz"
  }
}
```

The override or resolution setting replaces the `istanbul-lib-instrument` dependency used by the instrumentation plugin. Do not modify files directly under `node_modules`.

Place the Parasoft package file at the path used by the project. Make sure the path exists before reinstalling dependencies. Run the corresponding `install` command (`npm install`, `pnpm install`, or `yarn install`) to update the dependency tree. Verify that the lock file resolves `istanbul-lib-instrument` to the Parasoft package.

### 3. Add instrumentation to the build pipeline

Add the Istanbul-compatible instrumentation plugin at the build integration point used by the project. Keep the instrumentation step in the build that produces the application artifact; do not add it only to a test-only path when the goal is static coverage for the built project.

#### 3.1 Babel

Add `babel-plugin-istanbul` to the project's development dependencies, then add the `istanbul` plugin to the Babel configuration used by `babel-loader`, `@babel/cli`, Metro, or the relevant framework wrapper.

The `include` and `exclude` options are provided by `babel-plugin-istanbul` itself and select which of the files processed by the Babel build get instrumented. If they are not set in the plugin options, `babel-plugin-istanbul` also reads `include` and `exclude` from the `nyc` configuration.

```javascript
// babel.config.js
module.exports = {
    plugins: [
        ['babel-plugin-istanbul', {
            include: ['src/**/*.js', 'src/**/*.ts'],
            exclude: ['**/*.test.js', '**/*.test.ts']
        }]
    ],
    sourceMaps: true
};
```

#### 3.2 Vite

Add `vite-plugin-istanbul` to the project's development dependencies, then add it to the Vite plugin pipeline. Enable build instrumentation for the artifact produced by Vite.

The `include` and `exclude` options are provided by `vite-plugin-istanbul` itself and select which of the source files entering the Vite transform pipeline get instrumented. Use `extension` to cover file types beyond the plugin's defaults (for example `.ts`, `.vue`), and set `forceBuildInstrument: true` when instrumentation is required in Vite build mode.

```javascript
// vite.config.js
import { defineConfig } from 'vite';
import istanbul from 'vite-plugin-istanbul';

export default defineConfig({
    plugins: [
        istanbul({
            include: [
                'src/**/*.js',
                'src/**/*.ts'
            ],
            exclude: ['node_modules', 'test'],
            forceBuildInstrument: true
        })
    ]
});
```

For a framework wrapper, apply the same plugin and options through the framework's Vite extension point. Keep the instrumentation plugin in the build path that produces the final application artifact.

#### 3.3 Tsc
TODO

### 4. Configure source maps

Configure source maps at every build stage, including compilation, bundling, and minification, so the final artifact can be mapped back to the original source.

#### 4.1 TypeScript

Enable source-map generation in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "sourceMap": true
  }
}
```

#### 4.2 Babel

Enable source maps in the Babel configuration file, for example, `babel.config.json`:

```json
{
  "sourceMaps": true
}
```

If Babel runs through Webpack and `babel-loader`, also enable Webpack source maps, for example:

```javascript
// webpack.config.js
module.exports = {
    // existing Webpack settings
    devtool: 'source-map'
};
```

Do not discard the input source map when another loader or plugin processes the Babel output.

#### 4.3 `@babel/cli`

Pass `--source-maps` when compiling with the Babel CLI, or enable the equivalent option in the Babel configuration:

```powershell
npx babel src --out-dir dist --source-maps
```

#### 4.4 Vite

Enable source maps in `vite.config.*`:

```javascript
import { defineConfig } from 'vite';

export default defineConfig({
    build: {
        sourcemap: true
    }
});
```
For frameworks built on Vite, apply the equivalent `build.sourcemap: true` setting through the framework's Vite configuration hook.

### 5. Generate static coverage data

Static coverage generation is disabled by default. Enable it before the Node.js process loads the instrumentation package:

#### PowerShell

```powershell
$env:PARASOFT_STATIC_COVERAGE_ENABLE="true"
```

#### Windows Command Prompt

```bat
set PARASOFT_STATIC_COVERAGE_ENABLE=true
```

After setting the environment variable, run the normal build command used by the project. For example:

- npm: `npm run build`
- pnpm: `pnpm build`
- Yarn: `yarn build`

When `PARASOFT_STATIC_COVERAGE_ENABLE=true`, the instrumentation package writes per-file JSON coverage data in the build working directory with this structure:
```text
.parasoft/
└── static-coverage/
    └── <process-id>/
        ├── version.json
        ├── <file-name>-<uuid>.json
        └── ...
```

The instrumentation package writes one JSON file per instrumented source file. When source-map data is available, coverage locations are remapped to the original source files. It also writes `version.json` once per PID session directory. The manifest contains the static-coverage schema version and instrumentation package version.

### 6. Generate a coverage XML report with `parasoft-jscov.jar`

The Java CLI consumes a project root and reads `version.json` before recursively reading per-file static coverage JSON artifacts from its `.parasoft/static-coverage` directory. The distributed CLI artifact is named `parasoft-jscov.jar`.

#### 6.1 Usage

```powershell
java -jar parasoft-jscov.jar [coverage] [<arguments>]
```

The Arguments are:

| Arguments   | Requirement | Description                                                                                  |
|-------------|-------------|----------------------------------------------------------------------------------------------|
| `-app`      | Required    | The path to the project root containing the `.parasoft/static-coverage` directory.           |
| `-settings` | Optional    | The path to `settings.properties` file.                                                      |
| `-report`   | Optional    | The path to directory where the generated static coverage XML report is written.             |
| `-publish`  | Optional    | Uploads the generated reports to the DTP server. (Settings pattern: report.dtp.publish=true) |
| `-property` | Optional    | Specifies a custom configuration entry. You can use -property multiple times.                |

#### Examples

```powershell
java -jar parasoft-jscov.jar -app "/demo/project" -settings "settings.properties" -report "reports/static_coverage"

java -jar parasoft-jscov.jar coverage -app "/demo/project" -report "reports/static_coverage" -property "dtp.url=https://localhost:8443" -property "report.dtp.publish.src=full" -publish
```

#### 6.2 Configure settings

Copy the distributed `settings.properties` template and set only the values needed. Do not commit passwords or other secrets.

##### EULA setting

```properties
# Set to true to accept the Parasoft End User License Agreement (EULA).
# Please review the EULA.txt file included in the product installation directory.
parasoft.eula.accepted=true
```

##### License settings

```properties
# === LICENSE ===
# Configure only one license type. Do not enable both local and network licensing at the same time.

# === LOCAL LICENSE ===

# Enables local license - be sure to specify password.
ctp.license.use_network=false

# Specifies password for the local license.
ctp.license.local.password=[LICENSE PASSWORD]
```
```properties
# === NETWORK LICENSE ===

# Enables network license - be sure to configure DTP server settings.
ctp.license.use_network=true
```

##### DTP server settings

```properties
# === DTP SERVER SETTINGS ===

# Specifies URL of the DTP server in the form https://host:[port][/context-path]
dtp.url=https://<dtp-host>:<port>

# Specifies username for DTP server authentication.
dtp.user=<dtp-user>

# Specifies password for DTP server authentication - use -encodepass <PASSWORD> to encode the password, if needed.
dtp.password=<dtp-password>

# Specifies name of the DTP project - this setting is optional.
dtp.project=[DTP Project Name]

# === DTP REPORTING ===

# Enables reporting test results to DTP server - be sure to configure DTP server settings.
report.dtp.publish=true

# Specifies whether the tested source code is published to the DTP server.
#    off: Source code is not published to DTP.
#    min: The minimal part of the source code is published (in most cases, source code without reference to source control, for example, auto-generated code, is published).
#    full: All the source code from the specified scope is published to DTP. Default when the report.dtp.publish option is enabled.
report.dtp.publish.src=full
```

##### Console level setting
```properties
# Determines the amount of detail output to the console during analysis. 
#    low: Errors and basic information about the current steps and status (done, failed, up-to-date) are shown.
#    normal: Default. Shows the same information as the low setting, but also includes command lines executed and issues reported during test and analysis.
#    high: Shows the same information as normal, but also includes warnings.
console.verbosity.level=high
```

##### Technical support package settings
```properties
# Enables technical support data collecting, it automatically enable verbose logging.
techsupport.enabled=true

# Specifies the custom directory where support packages will be created.
techsupport.archive.location=C:\\parasoft\\temp
```

### 7. Troubleshooting and known limitations

#### 7.1 Static coverage data generation

- Static coverage data must currently be deleted manually.
  - The deletion can be configured in the `clean` script in `package.json`.
- Unit test runs may also use instrumentation.
  - Set or unset the coverage environment variable to disable static coverage JSON generation when needed.
  - The current `parasoft-istanbul-lib-instrument` implementation cannot determine whether the upstream process is a build or a test run, so the environment variable is the available control.
- Multiple workers may generate duplicate coverage JSON files.
  - The Java CLI skips JSON files with duplicate file names.
  - Jest may use multiple workers during a test run.

#### 7.2 DTP report representation and display

- Method names may be anonymous.
- Method hierarchy information may be missing.
- DTP may display a syntax error for code even when the JavaScript source itself has no syntax error.
  - Preliminary investigation suggests that this may be caused by outdated syntax support in the `ace-editor` component.

#### 7.3 Project metadata

- The project name and root path are obtained from the nearest `package.json` file.

#### 7.4 Coverage report structure

- Executable code that is not inside a method is reported in the `<global>` block.

## Runtime Coverage

This section describes collecting *runtime execution* coverage from a running Node.js application under test (AUT), which is separate from the static coverage workflow above.

### 1. Preload the agent

Preload the agent alongside the AUT entry point, supplying a runtime data directory:

```powershell
node --import .\agent.js aut-server.js --jscov.agent.runtimeData .\runtime-data
```

On Windows, pass an absolute agent path as a `file:///` URL; a bare drive-letter path such as `E:\path\agent.js` is not valid for `--import`.

### 2. Configure the agent

The agent accepts parameters via command-line arguments and an optional JSONC settings file (`--jscov.agent.settings ./agent.jsonc`). Command-line values take precedence over settings-file values, which take precedence over built-in defaults.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `jscov.agent.runtimeData` | *(required)* | Directory where runtime coverage data is stored. |
| `jscov.agent.settings` | — | Path to a JSONC settings file. CLI-only. |
| `jscov.agent.session.autostart` | `true` | Automatically start a coverage collection session. |
| `jscov.agent.restServerEnabled` | `true` | Enable the REST server for remote session access. |
| `jscov.agent.restServerPort` | `8050` | Port for the agent REST server. |
| `jscov.agent.debug` | `false` | Enable verbose debug output to the log file. |
| `jscov.agent.silentMode` | `false` | Suppress the agent introduction and info-level console output. |

### 3. Manage sessions over REST

The agent's REST server listens on `http://127.0.0.1:<restServerPort>` (default port `8050`). Use `GET`/`POST /session/start` and `GET`/`POST /session/stop` to manage the current session, and `GET /coverage`, `GET /coverage/{id}`, `DELETE /coverage/{id}` to list, download, or delete coverage archives. See `integration/jscov-agent/openapi.yml` for the full request/response contract, status codes, and error bodies.

### 4. Notes

- With autostart enabled (the default), the agent creates the default-user session before the REST server begins listening.
- Downloading a session archive requires `<runtimeData>/version.json` to exist.
