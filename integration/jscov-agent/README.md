# JSCov Agent

Temporary Node.js agent for JavaScript runtime coverage. It is preloaded alongside the application under test:

```powershell
node --import .\agent.js uta-server.js
```

When the agent is outside the current directory on Windows, pass its absolute path as a `file:///` URL. `--import` uses ESM resolution and rejects a bare drive-letter path such as `E:\path\agent.js`:

```powershell
node --import file:///E:/path/to/agent.js uta-server.js
```

The agent listens on port `8050`. 

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
