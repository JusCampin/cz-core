print('[cz-core] server main loaded')

-- ensure RPC module loaded (fxmanifest.lua loads server/rpc.lua before this file)
if not CZ_RPC then
	print('[cz-core] WARNING: CZ_RPC not found')
else
	-- example server RPC: returns player's identifiers (filter sensitive identifiers like IP)
	CZ_RPC.register('getPlayerIdentifiers', function(src)
		local ids = GetPlayerIdentifiers(src) or {}
		local filtered = {}
		for _, id in ipairs(ids) do
			if type(id) == 'string' and not id:match('^ip:') then
				table.insert(filtered, id)
			end
		end
		return filtered
	end)

	-- example server RPC: simple echo
	-- server echo handler removed
end

print('[cz-core] server RPC handlers registered')
