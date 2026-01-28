local function RunCore()
	SetupHeader()
	-- Start version checker (runs once). Calls `StartVersionChecker` defined in server/version_checker.lua
	if StartVersionChecker then
		pcall(StartVersionChecker)
	end
end

if GetCurrentResourceName() ~= "cz-core" then
    error("ERROR cz-core failed to load, resource must be named cz-core otherwise CoreZ Framework will not work properly")
else
    RunCore()
end

----------------------------------
-- EXAMPLE SERVER RPC REGISTRATION
if not CZ_RPC then
	print('[cz-core] WARNING: CZ_RPC not found')
else
	-- example server RPC: returns player's identifiers (filter sensitive identifiers like IP)
	CZ_RPC.register('getPlayerIdentifiers', function(source)
        local src = source
		local ids = GetPlayerIdentifiers(src) or {}
		local filtered = {}
		for _, id in ipairs(ids) do
			if type(id) == 'string' and not id:match('^ip:') then
				table.insert(filtered, id)
			end
		end
		return filtered
	end)
end
----------------------------------

-- Start version checker (non-blocking)
local ok, err = pcall(function()
	local resourceName = GetCurrentResourceName()
	local src = LoadResourceFile(resourceName, "server/version_checker.lua")
	if src then
		local fn, loadErr = load(src, "server/version_checker.lua")
		if fn then
			pcall(fn)
		else
			print((' [cz-core][version-checker] failed to load module: %s'):format(tostring(loadErr)))
		end
	else
		-- file missing: it's fine, checker is optional
	end
end)
if not ok then
	print((' [cz-core][version-checker] startup error: %s'):format(tostring(err)))
end

Core.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/JusCampin/cz-core')
