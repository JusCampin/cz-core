fx_version 'cerulean'
game 'gta5'

author 'CoreZ Team'
version '0.1.0'

shared_scripts {
    'configs/config.lua',
}

client_scripts {
    'client/rpc.lua',
    'client/main.lua',
    'client/commands.lua',
    'client/menus/menu_init.lua',
    'client/menus/spawn_menu.lua',
    'client/menus/car_menu.lua',
    'client/menus/gun_menu.lua',
    'client/menus/main_menu.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/rpc.lua',
    'server/setup.lua',
    'server/core_api.lua',
    'server/versioner.lua',
    'server/main.lua',
}

dependencies {
    'oxmysql'
}

exports 'GetCore'
