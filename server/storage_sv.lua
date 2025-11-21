local Config = Config

local coreType = nil
local QBCore = nil
local ESX = nil

CreateThread(function()
    if Config.Framework == 'qb' then
        coreType = 'qb'
        QBCore = exports['qb-core']:GetCoreObject()
        if Config.Debug then print('[x-storage] Forced QB-Core') end

    elseif Config.Framework == 'qbx' then
        coreType = 'qbx'
        if Config.Debug then print('[x-storage] Forced QBX Core') end

    elseif Config.Framework == 'esx' then
        coreType = 'esx'
        if GetResourceState('es_extended') == 'started' then
            ESX = exports['es_extended']:getSharedObject()
            if Config.Debug then print('[x-storage] Forced ESX') end
        else
            print('[x-storage] ERROR: es_extended not started')
        end

    else
        if GetResourceState('qbx_core') == 'started' then
            coreType = 'qbx'
            if Config.Debug then print('[x-storage] Auto: QBX Core detected') end
        elseif GetResourceState('qb-core') == 'started' then
            coreType = 'qb'
            QBCore = exports['qb-core']:GetCoreObject()
            if Config.Debug then print('[x-storage] Auto: QB-Core detected') end
        elseif GetResourceState('es_extended') == 'started' then
            coreType = 'esx'
            ESX = exports['es_extended']:getSharedObject()
            if Config.Debug then print('[x-storage] Auto: ESX detected') end
        else
            print('[x-storage] ERROR: No framework detected')
        end
    end
end)

local function GetPlayer(src)
    if coreType == 'qb' and QBCore then
        return QBCore.Functions.GetPlayer(src)
    elseif coreType == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    elseif coreType == 'esx' and ESX then
        return ESX.GetPlayerFromId(src)
    end
    return nil
end

local function getCitizenId(src)
    local Player = GetPlayer(src)
    if not Player then return nil end

    if coreType == 'esx' then
        local id = Player.getIdentifier and Player.getIdentifier() or Player.identifier
        if not id and Config.Debug then print('[x-storage] ESX identifier missing for', src) end
        return id
    else
        local pdata = Player.PlayerData
        if not pdata then return nil end

        local cid = pdata.CitizenId or pdata.citizenid or pdata.citizenId
        if not cid and Config.Debug then print('[x-storage] QB/QBX citizenid missing for', src) end
        return cid
    end
end

local function Notify(src, msg, typ)
    TriggerClientEvent('l_rentalstorage:notify', src, 'Storage Rental', msg, typ or 'inform')
end

local function chargePlayer(src, amount)
    local Player = GetPlayer(src)
    if not Player then return false end

    if coreType == 'esx' then
        if Config.MoneyAccount == 'bank' then
            local acc = Player.getAccount and Player.getAccount('bank')
            local money = acc and acc.money or 0
            if money >= amount then Player.removeAccountMoney('bank', amount) return true end
            return false
        else
            local cash = Player.getMoney and Player.getMoney() or 0
            if cash >= amount then Player.removeMoney(amount) return true end
            return false
        end
    else
        return Player.Functions.RemoveMoney(Config.MoneyAccount, amount, 'x-storage-rent')
    end
end

local function buildStashId(cid, loc)
    return ('xstorage_%s_loc%s'):format(cid, loc)
end

local function registerStash(row)
    if Config.Inventory ~= 'ox' then return end
    local loc = Config.Locations[row.location]
    if not loc then return end

    exports.ox_inventory:RegisterStash(
        row.stashid,
        ('%s - %s'):format(loc.label, row.citizenid),
        loc.stashSlots,
        loc.stashWeight,
        true
    )

    if Config.Debug then
        print('[x-storage] Registered stash:', row.stashid)
    end
end

CreateThread(function()
    if Config.Inventory ~= 'ox' then return end
    local rows = MySQL.query.await('SELECT * FROM rental_storage WHERE expire_at >= CURDATE()')
    if not rows then return end
    for _, row in ipairs(rows) do registerStash(row) end
end)

RegisterNetEvent('l_rentalstorage:tryAccess', function(locId)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local row = MySQL.single.await(
        'SELECT * FROM rental_storage WHERE citizenid = ? AND location = ? AND expire_at >= CURDATE()',
        { cid, locId }
    )

    if not row then
        TriggerClientEvent('l_rentalstorage:startRental', src, locId)
    else
        TriggerClientEvent('l_rentalstorage:enterPassword', src, locId)
    end
end)

RegisterNetEvent('l_rentalstorage:rentStorage', function(locId, durationKey, password)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local cfg = Config.Durations[durationKey]
    if not cfg then return Notify(src, 'Invalid rental option', 'error') end

    if cfg.price > 0 and not chargePlayer(src, cfg.price) then
        return Notify(src, 'Not enough money', 'error')
    end

    local expireDate = os.date('%Y-%m-%d', os.time() + (cfg.days * 86400))
    local stashId = buildStashId(cid, locId)

    local existing = MySQL.single.await(
        'SELECT id FROM rental_storage WHERE citizenid = ? AND location = ?',
        { cid, locId }
    )

    if existing then
        MySQL.update.await(
            'UPDATE rental_storage SET stashid=?, password=?, expire_at=? WHERE id=?',
            { stashId, password, expireDate, existing.id }
        )
    else
        MySQL.insert.await(
            'INSERT INTO rental_storage (citizenid, location, stashid, password, expire_at) VALUES (?, ?, ?, ?, ?)',
            { cid, locId, stashId, password, expireDate }
        )
    end

    registerStash({ citizenid = cid, location = locId, stashid = stashId })
    Notify(src, 'Storage rented for ' .. cfg.label, 'success')
end)

RegisterNetEvent('l_rentalstorage:openStorage', function(locId, pass)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local row = MySQL.single.await(
        'SELECT * FROM rental_storage WHERE citizenid = ? AND location = ? AND expire_at >= CURDATE()',
        { cid, locId }
    )

    if not row then return Notify(src, 'Rental expired or missing', 'error') end
    if row.password ~= pass then return Notify(src, 'Incorrect password', 'error') end

    registerStash(row)
    TriggerClientEvent('l_rentalstorage:openStash', src, row.stashid, locId)
end)

CreateThread(function()
    while true do
        MySQL.update.await(
            'DELETE FROM rental_storage WHERE expire_at < DATE_SUB(CURDATE(), INTERVAL 90 DAY)'
        )
        Wait(86400000)
    end
end)
