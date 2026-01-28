----------------------------------
-- EXAMPLE CLIENT RPC USAGE
if not CZ_RPC_CLIENT then
	print('[cz-core] WARNING: CZ_RPC_CLIENT not found')
else
	Citizen.CreateThread(function()
		Wait(1000)
		-- example: call server RPC to get identifiers
		CZ_RPC_CLIENT.triggerServer('getPlayerIdentifiers', {}, function(ok, res)
			if ok then
				print('Server returned identifiers: ' .. (json.encode and json.encode(res) or tostring(res)))
			else
				print('Server RPC error: ' .. tostring(res))
			end
		end)
	end)
end
----------------------------------
