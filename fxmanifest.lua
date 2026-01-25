fx_version 'cerulean'
game 'gta5'

author 'CoreZ Team'
description 'Core resource for CoreZ Framework'
version '1.0.0'

shared_scripts {
    'configs/config.lua',
}

client_scripts {
    'client/rpc.lua',
    'client/main.lua',
    'client/commands.lua',
    'client/menu.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/rpc.lua',
    'server/main.lua',
}

dependencies {
    'oxmysql'
}
