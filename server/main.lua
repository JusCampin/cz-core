local function RunCore()
	SetupHeader()
end

if GetCurrentResourceName() ~= "cz-core" then
    error("ERROR cz-core failed to load, resource must be named cz-core otherwise CoreZ Framework will not work properly")
else
    RunCore()
end

-- signal other server resources that cz-core has finished starting
TriggerEvent('cz-core:ready', GetCore())

-- NOTE: dev-mode is intentionally local to each resource to avoid global console spam.

----------------------------------
-- EXAMPLE SERVER RPC REGISTRATION
if not CZ_RPC then
	local okdev, dev = pcall(function() return (Config and Config.Dev and Config.Dev.enabled) or false end)
	if okdev and dev then print('WARNING: CZ_RPC not found') end
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

local okCore, Core = pcall(function() return GetCore() end)
if not okCore or not Core or not Core.Versioner or not Core.Versioner.checkFile then
	local okdev2, dev2 = pcall(function() return (Config and Config.Dev and Config.Dev.enabled) or false end)
	if okdev2 and dev2 then print('Core Versioner not available') end
else
	Core.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/JusCampin/cz-core')
end
