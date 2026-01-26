function CarMenu()
    local CarPage = CoreMenu:RegisterPage('car:page')

    CarPage:RegisterElement('header', {
        value = 'Car Menu',
        slot = "header",
        style = {
            ['color'] = '#999'
        }
    })

    CarPage:RegisterElement('subheader', {
        value = "Select an option below",
        slot = "header",
        style = {
            ['font-size'] = '0.94vw',
            ['color'] = '#CC9900'
        }
    })

    CarPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    CarPage:RegisterElement('button', {
        label = "Spawn Car",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        local model = 'adder'

        if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
            print('Invalid vehicle model: ' .. model)
            return
        end

        -- TODO: Add LoadModel function to utils
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
    end)

    CarPage:RegisterElement('button', {
        label = "Delete Car",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end)

    CarPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    CarPage:RegisterElement('button', {
        label = "Back",
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        MainMenu()
    end)

    CoreMenu:Open({
        startupPage = CarPage
    })
end
