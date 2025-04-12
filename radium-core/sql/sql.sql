CREATE TABLE IF NOT EXISTS `characters` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `csn` VARCHAR(12) NOT NULL,
  `identifier` VARCHAR(64) NOT NULL,
  `slot` INT NOT NULL,
  `name` VARCHAR(100),
  `gender` VARCHAR(10),
  `dob` DATE,
  `blood_type` VARCHAR(10),
  `job` VARCHAR(50),
  `job_grade` INT,
  `bank` INT DEFAULT 0,
  `last_location` LONGTEXT,
  `appearance` LONGTEXT
);

CREATE INDEX idx_identifier ON `characters` (`identifier`);

