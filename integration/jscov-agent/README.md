# JSCov Agent

Temporary Node.js agent for JavaScript runtime coverage. It is preloaded alongside the application under test:

```powershell
node --import .\agent.js aut-server.js
```

When the agent is outside the current directory on Windows, pass its absolute path as a `file:///` URL. `--import` uses ESM resolution and rejects a bare drive-letter path such as `E:\path\agent.js`:

```powershell
node --import file:///E:/path/to/agent.js aut-server.js
```

## Session start

The runtime data directory is required. Pass it as an agent argument after the application entry point:

```powershell
node --import .\agent.js aut-server.js --jscov.agent.runtimeData .\runtime-data
```

`jscov.agent.session.autostart` defaults to `true`. With the default setting, the
agent creates the default-user session before the REST server begins listening.
A later `GET` or `POST /session/start` request sees that existing session and
returns the duplicate-session response.

To defer session creation, disable autostart explicitly:

```powershell
node --import .\agent.js aut-server.js --jscov.agent.runtimeData .\runtime-data --jscov.agent.session.autostart=false
```

With autostart disabled, start the default-user session with either HTTP method
(the REST server listens on port `8050` by default):

```powershell
Invoke-RestMethod http://127.0.0.1:8050/session/start
Invoke-RestMethod -Method Post http://127.0.0.1:8050/session/start
```

Each successful request returns `200` with a generated session ID such as
`runtime_coverage_20260807_1603_0`. Session IDs follow the
`runtime_coverage_yyyyMMdd_HHmm_N` pattern. The agent reserves a file
initialized to `{}` (an empty JSON object) for the session at
`runtimeData/__default__/<session>.json`, where `runtimeData` is the required
argument value.

Set `jscov.agent.debug=true` to log session starts and duplicate rejections. If
autostart preparation fails, the Agent reports an Agent startup failure and
does not expose the REST server.

### Inspect runtime hit information in VS Code

To inspect the instrumented application's `__coverage__` data before and after manually starting a session, disable autostart when launching the application:

1. Open the `javascript-coverage` project in VS Code and select **Run and Debug** in the left sidebar.
2. Click **JavaScript Debug Terminal**. In the terminal that opens, run the Node command that starts the instrumented application with the agent preloaded and add `--jscov.agent.session.autostart=false`.
3. Select the **DEBUG CONSOLE** tab and enter `__coverage__` to inspect the hit information before starting a session.
4. Call `GET` or `POST /session/start`, then enter `__coverage__` again in **DEBUG CONSOLE** to inspect the hit information after the reset.

Only one default-user session may be active. A duplicate request returns `400`:

```json
{
  "messageCode": 150,
  "message": "Session is already started"
}
```

If session preparation fails, the server returns `500` with this contract; the
message contains the underlying error text:

```json
{
  "messageCode": 500,
  "message": "<error message>"
}
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
