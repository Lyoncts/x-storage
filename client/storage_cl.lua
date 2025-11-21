local Config = Config

RegisterNetEvent('l_rentalstorage:notify', function(title, desc, typ)
    lib.notify({
        title = title or 'Storage Rental',
        description = desc or '',
        type = typ or 'inform'
    })
end)

CreateThread(function()
    for id, loc in pairs(Config.Locations) do

        if (Config.Target == 'ox' or Config.Target == 'both')
        and GetResourceState('ox_target') == 'started' then

            exports.ox_target:addSphereZone({
                coords = loc.coords,
                radius = loc.targetRadius or 1.5,
                debug = Config.Debug,
                options = {{
                    name = 'xstorage_ox_' .. id,
                    label = loc.label .. ' Rental',
                    icon = 'fa-solid fa-box',
                    distance = loc.interactDistance or 2.0,
                    onSelect = function()
                        TriggerServerEvent('l_rentalstorage:tryAccess', id)
                    end
                }}
            })
        end

        if (Config.Target == 'qb' or Config.Target == 'both')
        and GetResourceState('qb-target') == 'started' then

            exports['qb-target']:AddBoxZone(
                'xstorage_qb_' .. id,
                loc.coords,
                1.5, 1.5,
                {
                    name = 'xstorage_qb_' .. id,
                    heading = 0.0,
                    debugPoly = Config.Debug,
                    minZ = loc.coords.z - 1.0,
                    maxZ = loc.coords.z + 1.0
                },
                {
                    options = {{
                        label = loc.label .. ' Rental',
                        icon  = 'fas fa-box',
                        action = function()
                            TriggerServerEvent('l_rentalstorage:tryAccess', id)
                        end
                    }},
                    distance = loc.interactDistance or 2.0
                }
            )
        end
    end
end)

RegisterNetEvent('l_rentalstorage:startRental', function(loc)
    local options = {}

    for key, cfg in pairs(Config.Durations) do
        options[#options+1] = {
            title = cfg.label,
            description = ('Price: $%s'):format(cfg.price),
            icon = 'fa-solid fa-clock',
            onSelect = function()
                local input = lib.inputDialog('Set Password', {{
                    type = 'input',
                    label = 'Password',
                    password = true,
                    required = true
                }})

                if not input or not input[1] or input[1] == '' then
                    lib.notify({
                        title = 'Storage Rental',
                        description = 'Password cannot be empty.',
                        type = 'error'
                    })
                    return
                end

                TriggerServerEvent('l_rentalstorage:rentStorage', loc, key, input[1])
            end
        }
    end

    lib.registerContext({
        id = 'rent_storage_' .. loc,
        title = 'Rent Storage',
        options = options
    })

    lib.showContext('rent_storage_' .. loc)
end)

RegisterNetEvent('l_rentalstorage:enterPassword', function(loc)
    local input = lib.inputDialog('Enter Password', {{
        type = 'input',
        label = 'Password',
        password = true,
        required = true
    }})

    if not input or not input[1] or input[1] == '' then
        lib.notify({
            title = 'Storage Rental',
            description = 'Password cannot be empty.',
            type = 'error'
        })
        return
    end

    TriggerServerEvent('l_rentalstorage:openStorage', loc, input[1])
end)

RegisterNetEvent('l_rentalstorage:openStash', function(stashId, locId)
    local loc = Config.Locations[locId]
    if not loc then return end

    if Config.Inventory == 'ox' then
        exports.ox_inventory:openInventory('stash', stashId)
    else
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId, {
            maxweight = loc.stashWeight,
            slots = loc.stashSlots
        })
        TriggerEvent('inventory:client:SetCurrentStash', stashId)
    end
end)
