local Config = ConfigStorage or Config

RegisterNetEvent('l_rentalstorage:notify', function(title, desc, typ)
    lib.notify({
        title = title or "Storage Rental",
        description = desc or "",
        type = typ or "inform"
    })
end)

-- Create zones
CreateThread(function()
    for id, loc in pairs(Config.Locations) do
        exports.ox_target:addSphereZone({
            coords = loc.coords,
            radius = loc.targetRadius or 1.5,
            debug = Config.Debug,
            options = {
                {
                    name = "xstorage_" .. id,
                    label = loc.label .. " Rental",
                    icon = "fa-solid fa-box",
                    distance = loc.interactDistance or 2.0,
                    onSelect = function()
                        TriggerServerEvent("l_rentalstorage:tryAccess", id)
                    end
                }
            }
        })
    end
end)

-- Rental menu
RegisterNetEvent('l_rentalstorage:startRental', function(loc)
    local options = {}

    for k, cfg in pairs(Config.Durations) do
        options[#options+1] = {
            title = cfg.label,
            description = "Price: $" .. cfg.price,
            icon = "fa-solid fa-clock",
            onSelect = function()
                local input = lib.inputDialog("Set Password", {
                    {
                        type = "input",
                        label = "Password",
                        password = true,
                        required = true
                    }
                })

                if input and input[1] then
                    TriggerServerEvent("l_rentalstorage:rentStorage", loc, k, input[1])
                end
            end
        }
    end

    lib.registerContext({
        id = "rent_storage_" .. loc,
        title = "Rent Storage",
        options = options
    })

    lib.showContext("rent_storage_" .. loc)
end)

-- Password input
RegisterNetEvent('l_rentalstorage:enterPassword', function(loc)
    local input = lib.inputDialog("Enter Password", {
        {
            type = "input",
            label = "Password",
            password = true,
            required = true
        }
    })

    if input and input[1] then
        TriggerServerEvent("l_rentalstorage:openStorage", loc, input[1])
    end
end)

-- Open stash
RegisterNetEvent('l_rentalstorage:openStash', function(id)
    exports.ox_inventory:openInventory("stash", id)
end)
