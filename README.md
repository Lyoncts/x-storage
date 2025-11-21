# x-storage
A simple storage rental system for FiveM.  
Supports Framework **QBCore**, **QBX**, **ESX**.
Supports Inventories **ox_inventory**, **qb-inventory**.
Supports Target **ox_target**, and **qb-target**.

## Features
- Rent personal storage at configured locations  
- Password-protected access  
- Player-unique stash per location  
- Rental options: **3 days**, **7 days**, **30 days**  
- Auto-delete expired storage after 3 months  
- DATE-based expiry (`YYYY-MM-DD`)  
- Works on all major frameworks & inventories  
- Configurable target system: **ox**, **qb**, or **both**

## Installation

### 1. Add SQL
```
CREATE TABLE IF NOT EXISTS `rental_storage` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(64) NOT NULL,
  `location` INT NOT NULL,
  `stashid` VARCHAR(128) NOT NULL,
  `password` VARCHAR(128) NOT NULL,
  `expire_at` DATE NOT NULL,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_location` (`citizenid`,`location`)
);
```

### 2. Configure
Edit `config_storage.lua`:

```
Config.Framework = 'auto'
Config.Inventory = 'ox'
Config.Target    = 'both'
Config.Debug     = false
```

### 3. Usage
Walk to any rental location and interact:
- Rent storage  
- Enter password  
- Access stash

### 4. Add to server.cfg
```
ensure x-storage
```

## Author
**L.cts**
