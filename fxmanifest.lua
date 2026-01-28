fx_version 'cerulean'
game 'gta5'

author 'CoreZ Team'
version '0.3.0'

shared_scripts {
    'configs/config.lua',
    'shared/log.lua',
    'shared/consumer_helper.lua',
    'shared/locale.lua',
    'languages/*.lua'
}

client_scripts {
    'client/rpc.lua',
    'client/core_api.lua',
    'client/main.lua',
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
