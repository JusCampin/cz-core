RegisterCommand('menu', function()
    MainMenu()
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
