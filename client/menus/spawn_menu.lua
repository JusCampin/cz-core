function SpawnMenu()
    local SpawnPage = CoreMenu:RegisterPage('spawn:page')

    SpawnPage:RegisterElement('header', {
        value = 'Spawn Menu',
        slot = "header",
        style = {
            ['color'] = '#999'
        }
    })

    SpawnPage:RegisterElement('subheader', {
        value = "Select an option below",
        slot = "header",
        style = {
            ['font-size'] = '0.94vw',
            ['color'] = '#CC9900'
        }
    })

    SpawnPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    SpawnPage:RegisterElement('button', {
        label = "Location 1",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        SetEntityCoords(PlayerPedId(), 969.25, 72.61, 116.18, false, false, false, true)
        SetEntityHeading(PlayerPedId(), 276.55)
    end)

    SpawnPage:RegisterElement('button', {
        label = "Location 2",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        SetEntityCoords(PlayerPedId(), 1104.49, 195.9, -49.44, false, false, false, true)
        SetEntityHeading(PlayerPedId(), 44.22)
    end)

    SpawnPage:RegisterElement('button', {
        label = "Location 3",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        SetEntityCoords(PlayerPedId(), -2163.87, 1134.51, -24.37, false, false, false, true)
        SetEntityHeading(PlayerPedId(), 310.05)
    end)

    SpawnPage:RegisterElement('button', {
        label = "Location 4",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        SetEntityCoords(PlayerPedId(), -996.71, -68.07, -99.0, false, false, false, true)
        SetEntityHeading(PlayerPedId(), 57.61)
    end)

    SpawnPage:RegisterElement('button', {
        label = "Location 5",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        SetEntityCoords(PlayerPedId(), -1023.45, -418.42, 67.66, false, false, false, true)
        SetEntityHeading(PlayerPedId(), 205.69)
    end)

    SpawnPage:RegisterElement('button', {
        label = "Location 6",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        SetEntityCoords(PlayerPedId(), 2265.27, 2925.02, -84.8, false, false, false, true)
        SetEntityHeading(PlayerPedId(), 267.77)
    end)

    SpawnPage:RegisterElement('button', {
        label = "Location 7",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        SetEntityCoords(PlayerPedId(), -1004.5, -478.51, 50.03, false, false, false, true)
        SetEntityHeading(PlayerPedId(), 28.19)
    end)

    SpawnPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    SpawnPage:RegisterElement('button', {
        label = "Back",
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        MainMenu()
    end)

    CoreMenu:Open({
        startupPage = SpawnPage
    })
end
