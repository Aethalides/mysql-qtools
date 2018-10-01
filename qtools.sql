/* This file is part of mysql-qtools.
Copyright 2018 Andy Pieters "Aethalides"
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>. */

-- NOTE that qtools is installed in the q database and that it will 
-- drop all contents of that database in the process of installing

SET @qtools_version="0.0.1";

SELECT CONCAT("Installing mysql-qtools version ",@qtools_version) AS `Info`;

DROP DATABASE IF EXISTS `q`;
CREATE DATABASE `q`;

USE `q`

CREATE TABLE `verinfo` (`version` CHAR(20) CHARACTER SET ascii NOT NULL) ENGINE=MYISAM;
INSERT INTO `verinfo` SET `version`=@qtools_version;

CREATE TABLE `syntax` (
	`subject` CHAR(50) CHARACTER SET ascii NOT NULL PRIMARY KEY,
	`help` CHAR(200) CHARACTER SET ascii NOT NULL
) ENGINE=MYISAM;

INSERT INTO `syntax` (`subject`,`help`)
VALUES
('version','Returns current version of qtools.'),
('help','Shows a list of available items.'),
('syntax',"Shows syntax information for specified item. USE: syntax('example');"),
('views','Shows a list of views in the currently selected database'),
('all_views','Shows a list of all the views ordered by database');

CREATE VIEW `version` AS SELECT CONCAT('mysql-qtools version ',`version`) AS `version` FROM `q`.`verinfo` LIMIT 1;
CREATE VIEW `views` AS SELECT `TABLE_NAME` AS `Views` FROM `information_schema`.`views` WHERE `TABLE_SCHEMA`=SCHEMA();
CREATE VIEW `all_views` AS SELECT `TABLE_SCHEMA` AS `Database`,`TABLE_NAME` AS `View` FROM `information_schema`.`views` ORDER BY `TABLE_SCHEMA` ASC;

CREATE VIEW `help` AS SELECT * FROM `q`.`syntax` ORDER BY `subject`;
DELIMITER ___

CREATE PROCEDURE version() BEGIN SELECT * FROM `q`.`version`; END; ___
CREATE PROCEDURE views() BEGIN SELECT * FROM `q`.`views`; END; ___
CREATE PROCEDURE syntax(strFunction CHAR(50)) BEGIN SELECT `help` FROM `q`.`syntax` WHERE `subject`=strFunction; END; ___
CREATE PROCEDURE help() BEGIN SELECT * FROM `q`.`help`; END; ___
CREATE PROCEDURE all_views() BEGIN SELECT * FROM `q`.`all_views`; END; ___
SELECT CONCAT("mysql-qtools version ",@qtools_version," has been installed") AS `Info` ___
SELECT "Delimiter has been set to ;" AS `Info` ___
DELIMITER ;
