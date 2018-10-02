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

-- VARIABLES INFLUENCING BEHAVIOR
SET @qtools_version="0.0.1";

/** Formatting locale to use.
	If you want to use whatever is currently defined, set it to:
	SET @qtools_lc=@@lc_time_names; */
SET @qtools_lc="en_GB";

/** Set to 1 for formatting functions to use base 2
	and KiB, MiB, etc prefixes.

	Set to 0 for formatting functions to use base 10
	and KB,MB, etc prefixes */
SET @qtools_si_base_2=1;

SET @qtools_original_schema=SCHEMA();
-- END VARIABLES

SELECT CONCAT("Installing mysql-qtools version ",@qtools_version) AS `Info`;

DROP DATABASE IF EXISTS `q`;
CREATE DATABASE `q`;

USE `q`;

CREATE TABLE `qtools` (
	`label` CHAR(20) NOT NULL PRIMARY KEY,
	`value` CHAR(20) NOT NULL
) ENGINE=MYISAM CHARSET=ascii
;

INSERT INTO `qtools` (`label`,`value`)
VALUES
('version',@qtools_version),
('si_base',IF(1=@qtools_si_base_2,0,1)),
('locale',@qtools_lc)
;

CREATE TABLE `syntax` (
	`subject` CHAR(50) NOT NULL PRIMARY KEY,
	`help` CHAR(200) NOT NULL
) ENGINE=MYISAM CHARACTER SET=ascii
;

INSERT INTO `syntax` (`subject`,`help`)
VALUES
('version','Returns current version of qtools.'),
('help','Shows a list of available items.'),
('syntax',"Shows syntax information for specified item. USE: CALL syntax('example');"),
('views','Shows a list of views in the currently selected database'),
('all_views','Shows a list of all the views ordered by database'),
('tables','Shows a formatted list of all the tables in the currently selected database'),
('formatInt','Formats integer to fixed with. USE: SELECT formatInt(42);'),
('formatSize','Formats integer file size. e.g. SELECT formatSize(1028); prints 1.004 KiB')
;

CREATE VIEW `version` AS
 SELECT CONCAT('mysql-qtools version ',`value`) AS `version`
 FROM `q`.`qtools`
 WHERE `label`='version'
 LIMIT 1
;

CREATE VIEW `views` AS
 SELECT `TABLE_NAME` AS `Views`
 FROM `information_schema`.`views`
 WHERE `TABLE_SCHEMA`=SCHEMA()
;

CREATE VIEW `all_views` AS
 SELECT `TABLE_SCHEMA` AS `Database`,
        `TABLE_NAME`   AS `View`
 FROM `information_schema`.`views`
;

CREATE VIEW `help` AS
 SELECT *
 FROM `q`.`syntax`
 ORDER BY `subject`
;

-- Some views need defining after functions they use have been defined

DELIMITER ___

CREATE PROCEDURE version()
 COMMENT 'Outputs the current qtools version string'
  LANGUAGE SQL
   READS SQL DATA
    DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT * FROM `q`.`version`;
END; ___

CREATE PROCEDURE syntax(strFunction CHAR(50))
 COMMENT 'Provides syntax help for specified routine/function/view'
  LANGUAGE SQL
   READS SQL DATA
    DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT `help` FROM `q`.`syntax` WHERE `subject`=strFunction;
END; ___

CREATE PROCEDURE help()
 COMMENT 'Produces a list with available qtools'
  LANGUAGE SQL
   READS SQL DATA
    DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT * FROM `q`.`help`;
END; ___

CREATE PROCEDURE all_views()
 COMMENT 'Produces an ordered list of views across all databases'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
BEGIN
	SELECT * FROM `q`.`all_views`;
END; ___

CREATE FUNCTION formatInt(in_value DECIMAL)
 RETURNS CHAR(15)
  CHARSET ascii
   COMMENT 'Formats an integer according to defined locale'
    LANGUAGE SQL
     READS SQL DATA
      DETERMINISTIC
       SQL SECURITY INVOKER
BEGIN
	RETURN LPAD(
	 FORMAT(
	  in_value,
	  0,
	  (
	   SELECT `value` 
	   FROM `q`.`qtools` 
	   WHERE `label`='locale'
	  )
	 ),
	 15,
	 ' '
	)
    ;
END; ___

CREATE function formatSize(intSize BIGINT(20) UNSIGNED)
 RETURNS CHAR(15)
  CHARSET ascii
   COMMENT 'Formats a file size according to chosen SI prefix'
    LANGUAGE SQL
     READS SQL DATA
      DETERMINISTIC
       SQL SECURITY INVOKER
BEGIN

	DECLARE multiplier TINYINT(1) UNSIGNED DEFAULT (SELECT `value` FROM `q`.`qtools` WHERE `label`='si_base' LIMIT 1);
	DECLARE UNITS CHAR(8) DEFAULT 'KMGTPEZY';
	DECLARE PAD_LENGTH TINYINT(2) UNSIGNED DEFAULT 8;
	DECLARE strOut CHAR(15) DEFAULT NULL;
	DECLARE blContinue BOOLEAN DEFAULT TRUE;
	DECLARE fltSize DECIMAL(30,10) DEFAULT ABS(CAST(intSize AS DECIMAL(30,10)));
	DECLARE intPosition TINYINT(1) UNSIGNED DEFAULT 0;
	DECLARE intMaxPosition TINYINT(1) UNSIGNED DEFAULT LENGTH(UNITS);
	DECLARE strUnit CHAR(3) DEFAULT NULL;
	DECLARE unit INT(4) UNSIGNED DEFAULT IF(multiplier=0,1024,1000);
	
	finished: WHILE intPosition < intMaxPosition DO

		IF fltSize >= unit THEN 

			SET fltSize=fltSize/unit;

			SET intPosition=intPosition+1;

		ELSE

			LEAVE finished;

		END IF;

	END WHILE;
	
	IF intPosition=0 THEN
	
		SET strUnit=CONCAT('B',IF(multiplier=0,'  ',' '));
		
	ELSE
	
		SET strUnit=CONCAT(SUBSTRING(UNITS,intPosition,1),IF(multiplier=0,'iB','B'));
		
	END IF;
	
	-- SET strOut=CONCAT(FORMAT(fltSize,3,(SELECT `value` FROM `q`.`qtools` WHERE `label`='locale')),' ',strUnit);

	SET strOut=FORMAT(fltSize,3,(SELECT `value` FROM `q`.`qtools` WHERE `label`='locale'));
	SET strOut=IF(PAD_LENGTH < LENGTH(strOut),strOut,LPAD(strOut,PAD_LENGTH,' '));
	SET strOut=CONCAT(strOut,' ',strUnit);
	
	return strOut;
END; ___

CREATE VIEW `tables` AS
 SELECT `TABLE_NAME` AS `table`,
        `ENGINE` AS `Type`,
        `q`.formatInt(`TABLE_ROWS`) AS `Records`,
        `q`.formatSize(`DATA_LENGTH`) AS `Data Size`,
        `q`.formatSize(`INDEX_LENGTH`) AS `Index Size`,
        `q`.formatSize(`INDEX_LENGTH`+`DATA_LENGTH`) AS `Total Size`,
        `CREATE_TIME` AS `Created`,
        `UPDATE_TIME` AS `Updated`,
        `CHECK_TIME` AS `Checked`
 FROM `information_schema`.`tables`
 WHERE `TABLE_SCHEMA`=SCHEMA() AND `TABLE_TYPE`='BASE TABLE'
 ORDER BY `DATA_LENGTH`+`INDEX_LENGTH` ASC,
          `TABLE_NAME` ASC
___

CREATE PROCEDURE qtools_install_finished()
BEGIN

	SELECT CONCAT(version,' has been installed') AS `Info`
	FROM `q`.`version`;
	
	IF SCHEMA()!=@qtools_original_schema THEN
		SELECT CONCAT("WARNING! Selected database changed from ",@qtools_original_schema," to ",SCHEMA()) AS `Warning`;
	END IF;
END;
___

CALL `q`.qtools_install_finished ___

DROP PROCEDURE `q`.qtools_install_finished ___

SELECT "Delimiter has been set to ;" AS `Info` ___

DELIMITER ;


