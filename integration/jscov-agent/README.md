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
  "message": "Session 'runtime_coverage_20260807_1603_0' is already started for user '__default__'"
}
```

If session preparation fails, the server returns `500` with a localized,
contextual error message. The file log retains the error trace for diagnostics:

```json
{
  "messageCode": 701,
  "message": "Failed to start a session for user '__default__': <error message>"
}
```

## Coverage files

List direct coverage files for the default user with `GET /coverage`:

```powershell
Invoke-RestMethod http://127.0.0.1:8050/coverage
```

The endpoint reads `runtimeData/__default__/`, where `runtimeData` is the
effective `jscov.agent.runtimeData` setting. It returns `200` and a
lexicographically sorted JSON array of file names without their final
extensions; an empty default-user directory returns `[]`. Subdirectories are
not returned.

If the default-user directory does not exist, the endpoint returns `404`:

```json
{
  "messageCode": 401,
  "message": "Cannot get coverage because user is not found"
}
```

The agent listens on port `8050`. 

## Session stop

Stop the default-user session with either HTTP method:

```powershell
Invoke-RestMethod http://127.0.0.1:8050/session/stop
Invoke-RestMethod -Method Post http://127.0.0.1:8050/session/stop
```

After a successful stop, the server returns `200` with the following body:

```json
{
  "session": null
}
```

Before closing the session, the agent writes the active session's coverage to
its session JSON file through an atomic replace. The active session is removed
only after that write succeeds. If persistence fails, the existing session JSON
file remains valid for retry. Debug and error diagnostics for stopping a session
identify the user/session or the concrete session-file path while intentionally
omitting coverage content.

If session persistence fails, the server returns `500` with a localized,
contextual error message. The file log retains the error trace for diagnostics:

```json
{
  "messageCode": 701,
  "message": "Failed to stop session 'runtime_coverage_20260807_1603_0' for user '__default__': <error message>"
}
```

If the default user is known to the running agent but does not have an active
session, the server returns `404`:

```json
{
  "messageCode": 200,
  "message": "Cannot stop a session for user '__default__' because it was not started"
}
```

If the default user has not successfully started a session in the running agent
process, the server instead returns `404`. This includes a disabled automatic
start with no successful `/session/start` request:

```json
{
  "messageCode": 103,
  "message": "User '__default__' was not found"
}
```

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
