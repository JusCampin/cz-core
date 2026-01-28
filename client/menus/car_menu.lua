function CarMenu()
    local CarPage = CoreMenu:RegisterPage('car:page')

    CarPage:RegisterElement('header', {
        value = 'Vehicle Menu',
        slot = "header",
        style = {
            ['color'] = '#999'
        }
    })

    CarPage:RegisterElement('subheader', {
        value = "Select an Option Below",
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

    local model
    CarPage:RegisterElement('dropdown', {
        label = 'Select Model',
        slot = "content",
        style = {
                ['color'] = '#E0E0E0'
            },
        options = {
            { text = "Hustler", value = "hustler" },
            { text = "Comet Retro", value = "comet3"},
            { text = "Trophy Truck", value = "trophytruck"},
            { text = "Zombie Bobber", value = "zombiea"},
            { text = "Sanchez", value = "sanchez2"},
            { text = "Seashark", value = "seashark"},
            { text = "Frogger", value = "frogger"},
            { text = "Dodo", value = "dodo"},
        },
    }, function(data)
        model = data.value
    end)

    CarPage:RegisterElement('button', {
        label = "Spawn",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        --local model = 'adder'

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
        label = "Delete",
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
