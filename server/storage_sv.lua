local Config = ConfigStorage or Config
local coreType = nil
local QBCore = nil

CreateThread(function()
    if GetResourceState("qbx_core") == "started" then
        coreType = "qbx"
        if Config.Debug then print("[x-storage] Using QBX Core") end
    elseif GetResourceState("qb-core") == "started" then
        coreType = "qbcore"
        QBCore = exports["qb-core"]:GetCoreObject()
        if Config.Debug then print("[x-storage] Using QB-Core") end
    else
        print("[x-storage] ERROR: No core detected (qb-core / qbx_core)!")
    end
end)

local function GetPlayer(src)
    if coreType == "qbx" then
        return exports.qbx_core:GetPlayer(src)
    elseif coreType == "qbcore" and QBCore then
        return QBCore.Functions.GetPlayer(src)
    end
    return nil
end

local function getCitizenId(src)
    local Player = GetPlayer(src)
    if not Player or not Player.PlayerData then return nil end

    local cid = Player.PlayerData.CitizenId
        or Player.PlayerData.citizenid
        or Player.PlayerData.citizenId

    if Config.Debug and not cid then
        print("[x-storage] WARNING: citizenid not found for src", src)
    end

    return cid
end

local function Notify(src, msg, typ)
    TriggerClientEvent("l_rentalstorage:notify", src, "Storage Rental", msg, typ or "inform")
end

local function chargePlayer(src, amount)
    local Player = GetPlayer(src)
    if not Player then return false end
    return Player.Functions.RemoveMoney(Config.MoneyAccount, amount, "x-storage-rent")
end

local function buildStashId(cid, loc)
    return ("xstorage_%s_loc%s"):format(cid, loc)
end

-- Stash Register (FIXED)
local function registerStash(row)
    local loc = Config.Locations[row.location]
    if not loc then return end

    -- L FIX:
    -- Do NOT owner-scope the stash (last argument must be false / nil),
    -- because stashid already contains citizenid+location.
    exports.ox_inventory:RegisterStash(
        row.stashid,
        ("%s - %s"):format(loc.label, row.citizenid),
        loc.stashSlots,
        loc.stashWeight,
        false
    )

    if Config.Debug then
        print(("[x-storage] Registered stash %s for %s at location %s"):format(row.stashid, row.citizenid, row.location))
    end
end

CreateThread(function()
    local rows = MySQL.query.await("SELECT * FROM rental_storage WHERE expire_at >= CURDATE()")
    if rows then
        for _, row in ipairs(rows) do
            registerStash(row)
        end
    end
end)

RegisterNetEvent("l_rentalstorage:tryAccess", function(locId)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local loc = Config.Locations[locId]
    if not loc then
        if Config.Debug then print("[x-storage] Invalid locationId in tryAccess:", locId) end
        return
    end

    local row = MySQL.single.await(
        "SELECT * FROM rental_storage WHERE citizenid = ? AND location = ? AND expire_at >= CURDATE()",
        { cid, locId }
    )

    if Config.Debug then
        if row then
            print(("[x-storage] tryAccess: found active rental for %s at loc %s, expire_at=%s"):format(cid, locId, row.expire_at))
        else
            print(("[x-storage] tryAccess: no active rental for %s at loc %s"):format(cid, locId))
        end
    end

    if not row then
        TriggerClientEvent("l_rentalstorage:startRental", src, locId)
    else
        TriggerClientEvent("l_rentalstorage:enterPassword", src, locId)
    end
end)

RegisterNetEvent("l_rentalstorage:rentStorage", function(locId, durationKey, password)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local loc = Config.Locations[locId]
    if not loc then
        if Config.Debug then print("[x-storage] rentStorage: invalid locId", locId) end
        return
    end

    local cfg = Config.Durations[durationKey]
    if not cfg then
        Notify(src, "Invalid duration selected.", "error")
        return
    end

    if cfg.price > 0 and not chargePlayer(src, cfg.price) then
        Notify(src, "Not enough money.", "error")
        return
    end

    local expireDate = os.date("%Y-%m-%d", os.time() + (cfg.days * 86400))
    local stashId = buildStashId(cid, locId)

    local existing = MySQL.single.await(
        "SELECT id FROM rental_storage WHERE citizenid = ? AND location = ?",
        { cid, locId }
    )

    if existing then
        MySQL.update.await(
            "UPDATE rental_storage SET stashid = ?, password = ?, expire_at = ? WHERE id = ?",
            { stashId, password, expireDate, existing.id }
        )
    else
        MySQL.insert.await(
            "INSERT INTO rental_storage (citizenid, location, stashid, password, expire_at) VALUES (?, ?, ?, ?, ?)",
            { cid, locId, stashId, password, expireDate }
        )
    end

    registerStash({ citizenid = cid, location = locId, stashid = stashId })
    Notify(src, "Storage rented for " .. cfg.label, "success")

    if Config.Debug then
        print(("[x-storage] rentStorage: %s loc %s expire_at=%s stash=%s"):format(cid, locId, expireDate, stashId))
    end
end)

RegisterNetEvent("l_rentalstorage:openStorage", function(locId, pass)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local loc = Config.Locations[locId]
    if not loc then
        if Config.Debug then print("[x-storage] openStorage: invalid locId", locId) end
        return
    end

    local row = MySQL.single.await(
        "SELECT * FROM rental_storage WHERE citizenid = ? AND location = ? AND expire_at >= CURDATE()",
        { cid, locId }
    )

    if not row then
        Notify(src, "Your storage rental has expired or does not exist.", "error")
        if Config.Debug then
            print(("[x-storage] openStorage: no active rental for %s at loc %s"):format(cid, locId))
        end
        return
    end

    if row.password ~= pass then
        Notify(src, "Incorrect password.", "error")
        if Config.Debug then
            print(("[x-storage] openStorage: wrong password for %s at loc %s"):format(cid, locId))
        end
        return
    end

    -- ensure stash exists + registered
    registerStash(row)

    -- open on client
    TriggerClientEvent("l_rentalstorage:openStash", src, row.stashid)

    if Config.Debug then
        print(("[x-storage] openStorage: opened stash %s for %s at loc %s"):format(row.stashid, cid, locId))
    end
end)

-- Auto Cleanup(3 months after expiry)
CreateThread(function()
    local deleted = MySQL.update.await(
        "DELETE FROM rental_storage WHERE expire_at < DATE_SUB(CURDATE(), INTERVAL 90 DAY)",
        {}
    )

    if Config.Debug and deleted and deleted > 0 then
        print("[x-storage] Cleanup: deleted " .. deleted .. " old rentals")
    end
end)
