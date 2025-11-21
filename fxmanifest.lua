fx_version 'cerulean'
game 'gta5'

name 'x-storage'
author 'L.cts'
description 'Storage Rental'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config_storage.lua'
}

client_scripts {
    'client/storage_cl.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/storage_sv.lua'
}

dependencies {
    'ox_lib'
    -- 'ox_inventory'   -- required if Config.Inventory = 'ox'
    -- 'qb-inventory'   -- required if Config.Inventory = 'qb'
    -- 'ox_target'      -- required if Config.Target uses 'ox' or 'both'
    -- 'qb-target'      -- required if Config.Target uses 'qb' or 'both'
}
