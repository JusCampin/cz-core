local function RunCore()
    SetupHeader()
end

if GetCurrentResourceName() ~= "cz-core" then
    error("ERROR cz-core failed to load, resource must be named cz-core otherwise CoreZ Framework will not work properly")
else
    RunCore()
end

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
