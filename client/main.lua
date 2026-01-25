print('[cz-core] client main loaded')

-- ensure RPC client module loaded (fxmanifest.lua loads client/rpc.lua before this file)
if not CZ_RPC_CLIENT then
	print('[cz-core] WARNING: CZ_RPC_CLIENT not found')
else
	-- client echo handler removed

	Citizen.CreateThread(function()
		Wait(1000)
		-- example: call server RPC to get identifiers
		CZ_RPC_CLIENT.triggerServer('getPlayerIdentifiers', {}, function(ok, res)
			if ok then
				print('[cz-core] server returned identifiers: ' .. (json.encode and json.encode(res) or tostring(res)))
			else
				print('[cz-core] server RPC error: ' .. tostring(res))
			end
		end)
	end)
end

local spawnPos = vector3(686.245, 577.950, 130.461)

AddEventHandler('onClientGameTypeStart', function()
    exports.spawnmanager:setAutoSpawnCallback(function()
        exports.spawnmanager:spawnPlayer({
            x = spawnPos.x,
            y = spawnPos.y,
            z = spawnPos.z,
            model = 'a_m_m_skater_01'
        }, function()
            TriggerEvent('chat:addMessage', {
                args = { 'Welcome to Apos Test Server!' }
            })
        end)
    end)

    exports.spawnmanager:setAutoSpawn(true)
    exports.spawnmanager:forceRespawn()
end)
