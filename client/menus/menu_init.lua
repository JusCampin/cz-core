FeatherMenu = exports['feather-menu'].initiate()

CoreMenu = FeatherMenu:RegisterMenu('core:main:menu', {
    top = '3%',
    left = '3%',
    ['720width'] = '400px',
    ['1080width'] = '500px',
    ['2kwidth'] = '600px',
    ['4kwidth'] = '800px',
    style = {
    },
    font = {
    },
    contentslot = {
        style = { --This style is what is currently making the content slot scoped and scrollable. If you delete this, it will make the content height dynamic to its inner content.
            ['height'] = '300px',
            ['min-height'] = '300px'
        }
    },
    draggable = true,
    canclose = true,
    keyclicks = { -- You can use https://tqlbox.com/key-codes to find the "key" values
        -- ['Backspace'] = function()
        --     print("Backspace clicked!")
        -- end,
        -- ['Delete'] = function()
        --     print("Delete clicked!")
        -- end
    }
}, {
    -- opened = function()
    --     print("MENU OPENED!")
    -- end,
    -- closed = function()
    --     print("MENU CLOSED!")
    -- end,
    -- topage = function(data)
    --     print("PAGE CHANGED ", data.pageid)
    -- end
})
