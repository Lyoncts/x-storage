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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
