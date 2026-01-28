# CZ Core - DO NOT USE - DEV ONLY

## Server APIs

cz-core exposes a small set of server-side helper APIs via the `GetCore()` export. Import with:

```lua
local Core = exports['cz-core']:GetCore()
```

RPC helper (server-side):

- `Core.RPC.raw` — the raw `CZ_RPC` table (if present)
- `Core.RPC.call(name, sourceOrNil, ...)` — convenience helper to invoke a registered server RPC handler directly and receive its return value synchronously.

Example — call a server RPC handler named `getPlayerIdentifiers`:

```lua
local ok, res = Core.RPC.call('getPlayerIdentifiers', nil, playerId)
if ok then
	print('identifiers:', res)
else
	print('rpc call failed:', res)
end
```

Version checker (Versioner):

cz-core provides a simple version-checker that can compare your local `version` file with the latest GitHub release or tag.

- `Core.Versioner.checkFile(resourceName, repoOrUrl, callback?)` — checks the given resource's `version` file against `repoOrUrl` (either `owner/repo` or a full GitHub URL). If `repoOrUrl` is omitted, `checkFile` will try to parse a `repo: ...` line from the resource's `version` file.
- `Core.waitForReady(cb)` — helper to receive a callback once cz-core is ready (useful for startup ordering).

Example — check the current resource against a GitHub repo and handle the result:

```lua
local Core = exports['cz-core']:GetCore()

Core.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/JusCampin/cz-core', function(ok, res, err)
		if not ok then
				print('version check failed:', err)
				return
		end
		if res.newer then
				print(('New version available — current: %s latest: %s'):format('0.2.0', res.latest))
		else
				print('Up-to-date')
		end
end)
```

Startup handshake example — run once core is ready:

```lua
local Core = exports['cz-core']:GetCore()
if Core.waitForReady then
	Core.waitForReady(function(c)
		c.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/JusCampin/cz-core')
	end)
else
	-- fallback
	c.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/JusCampin/cz-core')
end
```

Notes:

- The version checker prints to the server console when a newer version is found and will also print changelog lines when available in the resource's `version` file.
- Other resources should call `exports['cz-core']:GetCore()` (or use `Core.waitForReady`) rather than using global variables.
