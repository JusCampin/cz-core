function GunMenu()
    local GunPage = CoreMenu:RegisterPage('gun:page')

    GunPage:RegisterElement('header', {
        value = 'Gun Menu',
        slot = "header",
        style = {
            ['color'] = '#999'
        }
    })

    GunPage:RegisterElement('subheader', {
        value = "Select an Option Below",
        slot = "header",
        style = {
            ['font-size'] = '0.94vw',
            ['color'] = '#CC9900'
        }
    })

    GunPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    GunPage:RegisterElement('button', {
        label = "Give Gun",
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        local gunName = 'WEAPON_APPISTOL'

        if not IsWeaponValid(joaat(gunName)) then
            print('Invalid weapon model: ' .. gunName)
            return
        end

        GiveWeaponToPed(PlayerPedId(), joaat(gunName), 200, false, true)
    end)

    GunPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    GunPage:RegisterElement('button', {
        label = "Back",
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        },
    }, function()
        MainMenu()
    end)

    CoreMenu:Open({
        startupPage = GunPage
    })
end
