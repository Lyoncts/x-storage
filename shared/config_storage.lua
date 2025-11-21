Config = {}

-- Framework: 'qb' | 'qbx' | 'esx' | 'auto'
Config.Framework = 'auto'

-- Inventory system: 'ox' | 'qb'
--  'ox' = ox_inventory
--  'qb' = qb-inventory
Config.Inventory = 'ox'

-- Target: 'ox' | 'qb' | 'both'
Config.Target = 'both'

-- Debug prints
Config.Debug = false

-- 3 rental storage locations
Config.Locations = {
    [1] = {
        label = "Rental Storage A",
        coords = vector3(100.0, -1000.0, 29.0),
        targetRadius = 1.5,
        interactDistance = 2.0,
        stashSlots = 50,
        stashWeight = 500000
    },
    [2] = {
        label = "Rental Storage B",
        coords = vector3(300.0, -800.0, 29.0),
        targetRadius = 1.5,
        interactDistance = 2.0,
        stashSlots = 75,
        stashWeight = 750000
    },
    [3] = {
        label = "Rental Storage C",
        coords = vector3(500.0, -600.0, 29.0),
        targetRadius = 1.5,
        interactDistance = 2.0,
        stashSlots = 100,
        stashWeight = 1000000
    }
}

-- Rental durations
Config.Durations = {
    ["3d"]  = { label = "3 Days",  days = 3,  price = 10000 },
    ["7d"]  = { label = "7 Days",  days = 7,  price = 20000 },
    ["30d"] = { label = "30 Days", days = 30, price = 50000 }
}

-- 'bank' or 'cash'
Config.MoneyAccount = "bank"
