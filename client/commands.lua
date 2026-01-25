RegisterCommand('menu', function()
    OpenMainMenu()
end, false)

RegisterCommand('carSpawn', function(source, args, rawCommand)
    local model = args[1] or 'adder'

    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        TriggerEvent('chat:addMessage', {
            args = { 'Error: ' .. model .. ' is not a valid vehicle' }
        })
        return
    end

    RequestModel(model, false)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local myCar = CreateVehicle(model, playerCoords.x, playerCoords.y, playerCoords.z, heading, true, false)
    SetPedIntoVehicle(playerPed, myCar, -1)
    SetModelAsNoLongerNeeded(model)
end, false)

RegisterCommand('carDelete', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end, false)

RegisterCommand('+openhood', function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)

    if vehicle <= 0 then
        return
    end

    if not GetPedInVehicleSeat(vehicle, -1) == player then
        return
    end

    if GetVehicleDoorAngleRatio(vehicle, 4) >= 0.1 then
        SetVehicleDoorShut(vehicle, 4, false)
    else
        SetVehicleDoorOpen(vehicle, 4, false, false)
    end
end, false)

RegisterCommand('+opentrunk', function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, false)

    if vehicle <= 0 then
        return
    end

    if not GetPedInVehicleSeat(vehicle, -1) == player then
        return
    end

    if GetVehicleDoorAngleRatio(vehicle, 5) >= 0.1 then
        SetVehicleDoorShut(vehicle, 5, false)
    else
        SetVehicleDoorOpen(vehicle, 5, false, false)
    end
end, false)

RegisterKeyMapping('+openhood', 'Open Vehicle Hood', 'keyboard', 'PAGEUP')
RegisterKeyMapping('+opentrunk', 'Open Vehicle Trunk', 'keyboard', 'PAGEDOWN')

RegisterCommand('gun', function(source, args)
    local gunName = args[1] or 'WEAPON_APPISTOL'

    if not IsWeaponValid(joaat(gunName)) then
        TriggerEvent('chat:addMessage', {
            args = { 'Error: ' .. gunName .. ' is not a valid model' }
        })
        return
    end

    local player = PlayerPedId()
    GiveWeaponToPed(player, joaat(gunName), 200, false, true)
end, false)
