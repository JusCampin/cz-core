function MainMenu()
    local MainPage = CoreMenu:RegisterPage('main:page')

    MainPage:RegisterElement('header', {
        value = 'Main Menu',
        slot = "header",
        style = {
            ['color'] = '#999'
        }
    })

    MainPage:RegisterElement('subheader', {
        value = "Select an Option Below",
        slot = "header",
        style = {
            ['font-size'] = '0.94vw',
            ['color'] = '#CC9900'
        }
    })

    MainPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    MainPage:RegisterElement('button', {
        label = "Spawn",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        SpawnMenu()
    end)

    MainPage:RegisterElement('button', {
        label = "Car",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        CarMenu()
    end)

    MainPage:RegisterElement('button', {
        label = "Gun",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        GunMenu()
    end)

    MainPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    MainPage:RegisterElement('button', {
        label = "Close",
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        CoreMenu:Close()
    end)

    CoreMenu:Open({
        startupPage = MainPage
    })
end
