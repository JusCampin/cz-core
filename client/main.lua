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

local spawnPos = vector3(-540.58, -212.02, 37.65)

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
