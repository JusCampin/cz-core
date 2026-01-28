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

----------------------------------
-- EXAMPLE SERVER RPC REGISTRATION
if not CZ_RPC then
	print('WARNING: CZ_RPC not found')
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
	print('Core Versioner not available')
else
	Core.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/JusCampin/cz-core')
end
