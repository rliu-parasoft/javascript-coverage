# JSCov Agent

Temporary Node.js agent for JavaScript runtime coverage. It is preloaded alongside the application under test:

```powershell
node --import .\agent.js aut-server.js
```

When the agent is outside the current directory on Windows, pass its absolute path as a `file:///` URL. `--import` uses ESM resolution and rejects a bare drive-letter path such as `E:\path\agent.js`:

```powershell
node --import file:///E:/path/to/agent.js aut-server.js
```

The agent listens on port `8050`. 

## Configuration

The agent accepts parameters via command-line arguments and an optional JSONC settings file. Command-line values take precedence over settings-file values.

### Command-line arguments

```powershell
node --import .\agent.js aut-server.js ^
  --jscov.agent.runtimeData ./runtime-data ^
  --jscov.agent.settings ./agent.jsonc ^
  --jscov.agent.session.autostart=false ^
  --jscov.agent.restServerEnabled=true ^
  --jscov.agent.restServerPort 8050 ^
  --jscov.agent.debug ^
  --jscov.agent.silentMode
```

### Settings file (`agent.jsonc`)

Point `--jscov.agent.settings` to a JSONC file. Comments and trailing commas are accepted:

```jsonc
{
    // Specifies where the runtime data will be stored
    "jscov.agent.runtimeData": "/path/to/runtime/coverage",
    // Enables/disables automatic start of a runtime data collection session
    "jscov.agent.session.autostart": true,
    // Enables/disables remote access to coverage sessions
    "jscov.agent.restServerEnabled": true,
    // Sets up agent REST server communication port
    "jscov.agent.restServerPort": 8050,
    // Enables/disables verbose output to log file
    "jscov.agent.debug": false,
    // Turns off agent introduction printed out to console
    "jscov.agent.silentMode": false
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `jscov.agent.runtimeData` | string | *(required)* | Directory where runtime coverage data is stored. |
| `jscov.agent.settings` | string | — | Path to a JSONC settings file. CLI-only (cannot be set inside the file). |
| `jscov.agent.session.autostart` | boolean | `true` | Automatically start a coverage collection session. |
| `jscov.agent.restServerEnabled` | boolean | `true` | Enable the REST server for remote session access. |
| `jscov.agent.restServerPort` | number | `8050` | Port for the agent REST server. |
| `jscov.agent.debug` | boolean | `false` | Enable verbose debug output to the log file. |
| `jscov.agent.silentMode` | boolean | `false` | Suppress the agent banner printed to the console. |

### Precedence

1. Command-line arguments (`ARGS`)
2. Settings file values (`SETTINGS_FILE`)
3. Built-in defaults

### Error handling

If the settings file is missing, unreadable, points to a directory, or contains malformed JSONC, the agent logs an `ERROR` to standard error and does **not** start. The target Node.js process continues running unaffected.

## Commands

Run these commands from `integration/jscov-agent/`:

```powershell
npm run build
npm test
npm run lint:report
```

For the Gradle lifecycle, run the repository wrapper from the project root:

```powershell
.\gradlew.bat :integration:jscov-agent:test
.\gradlew.bat distribution
```

The module build creates `dist/agent.js`. The root distribution places `agent.js` and `agent.jsonc` in `integration/jscov-agent/` inside the release ZIP.
