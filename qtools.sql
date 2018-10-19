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
	`type` SET('FUNCTION','VIEW','PROCEDURE') NOT NULL DEFAULT 'VIEW',
	`help` CHAR(200) NOT NULL
) ENGINE=MYISAM CHARACTER SET=ascii
;

INSERT INTO `syntax` (`subject`,`type`,`help`)
VALUES
('all_functions','VIEW,PROCEDURE','Shows a list of all the functions across all databases'),
('all_views','VIEW,PROCEDURE','Shows a list of all the views ordered by database'),
('all_procedures','VIEW,PROCEDURE','Shows a list of all the procedures across all databases'),
('all_tables','VIEW,PROCEDURE','Shows a formatted list of all the tables in all the databases'),
('all_events','VIEW,PROCEDURE','Shows a formatted list of all the events in all the databases'),
('events','VIEW,PROCEDURE','Shows a formatted list of all the events in the currently selected database. Procedure use CALL q.events(schema)'),
('formatInt','FUNCTION','Formats integer to fixed with. USE: SELECT formatInt(42);'),
('formatSize','FUNCTION','Formats integer file size. e.g. SELECT formatSize(1028); prints 1.004 KiB'),
('functions','PROCEDURE,VIEW','Shows a list of functions in the currently selected database. Procedure use CALL q.functions(schema)'),
('help','VIEW,PROCEDURE','Shows a list of available qtools routines.'),
('help_views','PROCEDURE','Shows a list of available qtools views'),
('procedures','PROCEDURE,VIEW','Shows a list available procedures in the database. Procedure use CALL q.procedures(schema)'),
('syntax','VIEW,PROCEDURE','Shows syntax information for specified item. Procedure use: CALL q.syntax(routine_name)'),
('routines','VIEW,PROCEDURE','Shows a list of functions and procedures in the currently selected database'),
('tables','VIEW,PROCEDURE','Shows a formatted list of all the tables in the currently selected database. Procedure use: CALL q.tables(schema)'),
('version','VIEW,PROCEDURE','Returns current version of qtools.'),
('views','VIEW,PROCEDURE','Shows a list of views in the currently selected database. Procedure use: CALL q.views(schema)')
;

CREATE SQL SECURITY INVOKER VIEW `version` AS
 SELECT CONCAT('mysql-qtools version ',`value`) AS `version`
 FROM `q`.`qtools`
 WHERE `label`='version'
 LIMIT 1
;

CREATE SQL SECURITY INVOKER VIEW `views` AS
 SELECT `TABLE_NAME` AS `Views`
 FROM `INFORMATION_SCHEMA`.`views`
 WHERE `TABLE_SCHEMA`=SCHEMA()
;

CREATE SQL SECURITY INVOKER VIEW `all_views` AS
 SELECT `TABLE_SCHEMA` AS `Database`,
        `TABLE_NAME`   AS `View`
 FROM `INFORMATION_SCHEMA`.`views`
 ORDER BY `TABLE_SCHEMA`
;

CREATE SQL SECURITY INVOKER VIEW `procedures` AS
 SELECT 
	`ROUTINE_NAME` AS `Procedure`,
	CONCAT
	(
		`ROUTINE_NAME`,
		'(',
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 'void'
		),
		')'
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 WHERE `routine_type`='PROCEDURE' AND `routine_schema`=SCHEMA()
 ORDER BY `ROUTINE_TYPE` ASC, `ROUTINE_NAME` ASC
;

CREATE SQL SECURITY INVOKER VIEW `functions` AS
 SELECT 
	`ROUTINE_NAME` AS `Function`,
	CONCAT
	(
		IF(`DATA_TYPE`='','void',UPPER(`DATA_TYPE`)),' ',
		`ROUTINE_NAME`,
		'(',
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 'void'
		),
		')'
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 WHERE `routine_schema`=SCHEMA() AND `routine_type`='FUNCTION'
 ORDER BY `ROUTINE_TYPE` ASC, `ROUTINE_NAME` ASC
;

CREATE SQL SECURITY INVOKER VIEW `all_functions` AS
 SELECT 
	`ROUTINE_NAME` AS `Function`,
	CONCAT
	(
		IF(`DATA_TYPE`='','void',UPPER(`DATA_TYPE`)),' ',
		`ROUTINE_NAME`,
		'(',
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 'void'
		),
		')'
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 WHERE `routine_type`='FUNCTION'
 ORDER BY `ROUTINE_SCHEMA` ASC,`ROUTINE_TYPE` ASC, `ROUTINE_NAME` ASC
;

CREATE SQL SECURITY INVOKER VIEW `all_procedures` AS
 SELECT 
	`ROUTINE_SCHEMA` AS `Database`,
	`ROUTINE_NAME` AS `Procedure`,
	CONCAT
	(
		`ROUTINE_NAME`,
		'(',
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 'void'
		),
		')'
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 WHERE `routine_type`='PROCEDURE'
 ORDER BY `ROUTINE_SCHEMA`,`ROUTINE_TYPE` ASC, `ROUTINE_NAME` ASC
;

CREATE SQL SECURITY INVOKER VIEW `routines` AS
 SELECT 
	`ROUTINE_NAME` AS `Routine`,
	`ROUTINE_TYPE` AS `Type`,
	CONCAT
	(
		IF(`DATA_TYPE`='','void',UPPER(`DATA_TYPE`)),' ',
		`ROUTINE_NAME`,
		'(',
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 'void'
		),
		')'
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 WHERE `routine_schema`=SCHEMA()
 ORDER BY `ROUTINE_TYPE` ASC, `ROUTINE_NAME` ASC
;

CREATE SQL SECURITY INVOKER VIEW `all_routines` AS
 SELECT 
	`ROUTINE_SCHEMA` AS `Database`,
	`ROUTINE_NAME` AS `Routine`,
	`ROUTINE_TYPE` AS `Type`,
	CONCAT
	(
		IF(`DATA_TYPE`='','void',UPPER(`DATA_TYPE`)),' ',
		`ROUTINE_NAME`,
		'(',
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 'void'
		),
		')'
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 ORDER BY 
	`ROUTINE_SCHEMA` ASC,
	`ROUTINE_TYPE` ASC, 
	`ROUTINE_NAME` ASC
;

CREATE SQL SECURITY INVOKER VIEW `help` AS
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
	SELECT `help`,`type` FROM `q`.`syntax` WHERE `subject`=strFunction AND (`type` & 4 OR `type` & 1);
END; ___

CREATE PROCEDURE help()
 COMMENT 'Produces a list with available qtools'
  LANGUAGE SQL
   READS SQL DATA
    DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT 'Showing available routines. ' AS `Info` UNION
	SELECT 'Some routines are also available as VIEW' AS `Info` UNION
	SELECT 'See help for views with CALL help_views;' AS `Info`;

	SELECT * FROM `q`.`help` WHERE `type` & 4 OR `type` & 1;
END; ___

CREATE PROCEDURE help_views()
 COMMENT 'Produces a list with available qtools views'
  LANGUAGE SQL
   READS SQL DATA
    DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT 'Showing available views.' AS `Info` UNION
	SELECT 'Some views are also available as routine' As `Info`;
	
	SELECT * FROM `q`.`help` WHERE `type` & 2;
END; ___

CREATE PROCEDURE all_views()
 COMMENT 'Produces an ordered list of views across all databases'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT * FROM `q`.`all_views`;
END; ___

CREATE PROCEDURE all_tables()
 COMMENT 'Produces a formatted list of all tables across all databases'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT * FROM `q`.`all_tables`;
END; ___

CREATE PROCEDURE all_functions()
 COMMENT 'Produces an ordered list of available functions across all databases'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT * FROM `q`.`all_functions`;
END; ___

CREATE PROCEDURE all_routines()
 COMMENT 'Shows a list of all functions and procedures across all databases'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT * FROM `q`.`all_routines`;
END; ___

CREATE PROCEDURE all_procedures()
 COMMENT 'Shows a list of all procedures across all databases'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT * FROM `q`.`all_procedures`;
END; ___

CREATE FUNCTION formatInt(in_value DECIMAL)
 RETURNS TEXT
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
	 9,
	 ' '
	)
    ;
END; ___

CREATE FUNCTION formatSize(intSize BIGINT(20) UNSIGNED)
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
	
	SET strOut=FORMAT(fltSize,3,(SELECT `value` FROM `q`.`qtools` WHERE `label`='locale'));
	
	SET strOut=IF(PAD_LENGTH < LENGTH(strOut),strOut,LPAD(strOut,PAD_LENGTH,' '));

	SET strOut=CONCAT(strOut,' ',strUnit);
	
	return strOut;
END; ___

CREATE FUNCTION substr_count(
	haystack TEXT CHARSET ascii,
	needle TEXT CHARSET ascii
) RETURNS SMALLINT(3) UNSIGNED
    COMMENT "Count the number of substring occurrences (not case sensitive)"
     LANGUAGE SQL
      CONTAINS SQL
       DETERMINISTIC
        SQL SECURITY INVOKER
BEGIN
	DECLARE beginCount INT(11) UNSIGNED DEFAULT CHAR_LENGTH(haystack);
	DECLARE replaced TEXT DEFAULT REPLACE(haystack,needle,'');
	RETURN (beginCount-CHAR_LENGTH(replaced))/CHAR_LENGTH(needle);
END; ___

CREATE FUNCTION formatQuartetCompoundTime(
	inEvery VARCHAR(256), unitName VARCHAR(18),
	  unit1 VARCHAR(18), unit2 VARCHAR(18),
	  unit3 VARCHAR(18), unit4 VARCHAR(18)
) 
 RETURNS TEXT
  CHARSET ascii
   COMMENT 'Human readable format of time quartets'
    LANGUAGE SQL
     READS SQL DATA
      DETERMINISTIC
       SQL SECURITY INVOKER
BEGIN
	DECLARE cpos SMALLINT(1) DEFAULT LOCATE(':',inEvery);
	DECLARE ccount SMALLINT(1) UNSIGNED DEFAULT `q`.`substr_count`(inEvery,':');
	DECLARE unit1s SMALLINT(1) UNSIGNED DEFAULT SUBSTRING(inEvery FROM 1 FOR cpos-1);
	DECLARE remainingUnits VARCHAR(18) DEFAULT SUBSTRING(inEvery FROM cpos+1);
	DECLARE errorDescription TEXT CHARSET ascii DEFAULT NULL;
	DECLARE trailingPart TEXT DEFAULT `q`.`formatTrippleCompoundTime`(
		remainingUnits,unitName,unit2,unit3,unit4
	);
	
	IF 1 = unit1s THEN
	
		IF trailingPart IS NULL THEN
		
			RETURN CONCAT("1 ",unit1);
			
		ELSE
		
			RETURN CONCAT("1 ", unit1s," and ",trailingPart);
			
		END IF;
	
	ELSE
	
		IF trailingPart IS NULL THEN
		
			RETURN CONCAT(unit1s," ",unit1,'s');
			
		ELSE
		
			RETURN CONCAT(unit1s," ",unit1,"s and ",trailingPart);
			
		END IF;
	END IF;
	
	RETURN NULL;
END;

CREATE FUNCTION formatTrippleCompoundTime(
	inEvery VARCHAR(256),unitName VARCHAR(18),unit1 VARCHAR(18),
	unit2 VARCHAR(18), unit3 VARCHAR(18)
) 
 RETURNS TEXT
  CHARSET ascii
   COMMENT 'Human readable format of time trios'
    LANGUAGE SQL
     READS SQL DATA
      DETERMINISTIC
       SQL SECURITY INVOKER
BEGIN
	DECLARE cpos SMALLINT(1) DEFAULT LOCATE(':',inEvery);
	DECLARE ccount SMALLINT(1) UNSIGNED DEFAULT `q`.`substr_count`(inEvery,':');
	DECLARE unit1s SMALLINT(1) UNSIGNED DEFAULT SUBSTRING(inEvery FROM 1 FOR cpos-1);
	DECLARE remainingUnits VARCHAR(18) DEFAULT SUBSTRING(inEvery FROM cpos+1);
	DECLARE errorDescription TEXT CHARSET ascii DEFAULT NULL;
	DECLARE trailingPart TEXT DEFAULT `q`.`formatDoubleCompoundTime`(
		remainingUnits,unitName, unit2,unit3
	);
	
	IF 1 = unit1s THEN
	
		IF trailingPart IS NULL THEN
		
			RETURN CONCAT("1 ",unit1);
			
		ELSE
		
			RETURN CONCAT("1 ", unit1," and ",trailingPart);
			
		END IF;
	
	ELSE
	
		IF trailingPart IS NULL THEN
		
			RETURN CONCAT(unit1s," ",unit1,'s');
			
		ELSE
		
			RETURN CONCAT(unit1s," ",unit1,'s'," and ",trailingPart);
		END IF;
	END IF;
	
	RETURN NULL;
END; ___

CREATE FUNCTION formatDoubleCompoundTime(
	inEvery VARCHAR(256), unitName VARCHAR(18),
	unit1 VARCHAR(18), unit2 VARCHAR(18)
)
 RETURNS TEXT
   CHARSET ascii
    COMMENT 'Human readable format of time duets'
     LANGUAGE SQL
      READS SQL DATA
       DETERMINISTIC
        SQL SECURITY INVOKER
BEGIN
	DECLARE cpos SMALLINT(1) DEFAULT LOCATE(':',inEvery);
	DECLARE ccount SMALLINT(1) UNSIGNED DEFAULT `q`.`substr_count`(inEvery,':');
	DECLARE firstunits SMALLINT(1) UNSIGNED DEFAULT SUBSTRING(inEvery FROM 1 FOR cpos-1);
	DECLARE secondunits SMALLINT(1) UNSIGNED DEFAULT SUBSTRING(inEvery FROM cpos+1);
	DECLARE description TEXT CHARSET ascii DEFAULT NULL;
	
	IF(1<>ccount) THEN
	
		SET description=CONCAT("formatDoubleCompoundTime(): syntax error for ",unitName," value `",inEvery,"', expected 1 occurence of ':', got ",ccount);
			SIGNAL SQLSTATE '45001' 
			SET MESSAGE_TEXT=description;
		
	END IF;
	
	CASE firstunits
	
		WHEN 0 THEN RETURN IF
		(
			0=secondunits,NULL,
			IF
			(
				1=secondunits,CONCAT("1 ",unit2),CONCAT(secondunits," ",unit2,'s')
			)
		);
		
		WHEN 1 THEN RETURN IF(
			
			0=secondunits,
			
			unit1,
			
			IF(
			
				1=secondunits,
				
				CONCAT("1 ",unit1," and 1 ",unit2),
				
				CONCAT("1 ",unit1," and ",secondunits," ",unit2,'s')
			)
		);
		
		ELSE RETURN IF(
		
			0=secondunits,
			
			CONCAT(firstunits," ",unit1,'s'),
			
			IF(
			
				1=secondunits,
				
				CONCAT(firstunits," ",unit1,'s'," and 1 ",unit2),
				
				CONCAT(firstunits," ",unit1,'s'," and ", secondunits," ", unit2,'s')
			)
		);
		
	END CASE;
END; ___

create table yourmom (message text) ENGINE=MyISAM; ___

CREATE FUNCTION formatEventTime(
	inTimeZone VARCHAR(64),inAt DATETIME,
	inStart DATETIME,inEnds DATETIME,
	inEvery VARCHAR(256),inUnit VARCHAR(18)
	
) RETURNS TEXT
   CHARSET ascii
    COMMENT 'Human readable format of event lifetime and schedule'
     LANGUAGE SQL
      READS SQL DATA
       DETERMINISTIC
        SQL SECURITY INVOKER
BEGIN
	DECLARE description VARCHAR(256) DEFAULT '';
	
	SET inEvery=REPLACE(inEvery,"'","");
	
	IF inUnit IN ('SECOND','MINUTE','HOUR','DAY','WEEK','MONTH','QUARTER','YEAR') AND inEvery REGEXP '^[0-9]+$' = 0 THEN
	
		SIGNAL SQLSTATE '45001' 
		SET MESSAGE_TEXT="formatEventTime() syntax error. inEvery parameter must be an integer for given inUnit parameter";

	END IF;
	
	IF inEvery IS NULL THEN
	
		SET description=CONCAT("Once at ",inAT,IF("SYSTEM"=inTimeZone,"",CONCAT(" (",inTimeZone,")")));
		
	ELSE
	
		CASE inUnit

			WHEN 'SECOND'   THEN SET description=IF(1=inEvery,"Every second",CONCAT("Every ",inEvery," seconds"));

			WHEN 'MINUTE'   THEN SET description=IF(1=inEvery,"Every minute",CONCAT("Every ",inEvery," minutes"));

			WHEN 'HOUR'     THEN SET description=IF(1=inEvery,"Hourly",CONCAT("Every ",inEvery," hours"));
			
			WHEN 'DAY'      THEN SET description=IF(1=inEvery,"Daily",CONCAT("Every ",inEvery," days"));
			
			WHEN 'WEEK'     THEN SET description=IF(1=inEvery,"Weekly",CONCAT("Every ",inEvery," weeks"));

			WHEN 'MONTH'    THEN SET description=IF(1=inEvery,"Monthly",CONCAT("Every ",inEvery," months"));

			WHEN 'QUARTER'  THEN SET description=IF(1=inEvery,"Quarterly",CONCAT("Every ",inEvery," quarters"));

			WHEN 'YEAR'     THEN SET description=IF(1=inEvery,"Yearly",CONCAT("Every ",inEvery," years"));
			
			/* duets */
			
			WHEN 'MINUTE_SECOND' THEN SET description=CONCAT
			(
				"Every ",
				
				`q`.`formatDoubleCompoundTime`
				(
					inEvery,inUnit,'minute','minutes','second','seconds'
				)
			);
			
			WHEN 'HOUR_MINUTE' THEN SET description=CONCAT("Every ",`q`.`formatDoubleCompoundTime`(inEvery,inUnit,'hour','minute'));

			WHEN 'DAY_HOUR' THEN SET description=CONCAT("Every ",`q`.`formatDoubleCompoundTime`(inEvery,inUnit,'day','hour'));


			/* trios */
			
			WHEN 'HOUR_SECOND' THEN set description=CONCAT
			(
				"Every ",
				
				`q`.`formatTrippleCompoundTime`
				(
					inEvery,inUnit,'hour','minute','second'
				)
			);
			
			WHEN 'DAY_MINUTE' THEN set description=CONCAT
			(
			
				"Every ",
				
				`q`.`formatTrippleCompoundTime`
				(
				
					REPLACE(inEvery,' ',':'),inUnit,
					
					'day','hour','minute'
				)
			);
			
			/* quartets */
			
			WHEN 'DAY_SECOND' THEN SET description=CONCAT
			(
			
				"Every ",
				
				`q`.`formatQuartetCompoundTime`
				(
				
					REPLACE(inEvery,' ',':'),inUnit,
					
					'day','hour','minute','second'
				)
			);
			
		END CASE;
	
		SET description=REPLACE(REPLACE(description,"Every 1 day and","Daily, every"),"every 1 hour and","every hour,");
		
		IF 1<q.substr_count(description," and ") THEN
		
			/* replace descriptions like "2 days and 2 hours and 5 minutes and 6 seconds
				into 2 days, 2 hours, 5 minutes, and 6 seconds */

			-- first step for this process is to replace *all* the "AND" instances with comma space
			
			SET description=REPLACE
			(
				description," and ", ", "
			);
			
			/* next is to reverse the text and get the position of the first comma 
				(which is actually the position of the last comma on the un-reversed text),
			    then insert ", and" on that position and Robert is your mother's brother */
				
			SET description=INSERT
			(
				description,
				
				LENGTH(description)-LOCATE(',',REVERSE(description))+1,
				
				1,
				
				", and"
			);
			
			-- tack on start & end times if relevant 

			IF NOT inStart IS NULL THEN
		
				SET description=CONCAT(description,". From ",inStart);
			
			END IF;
		
			IF NOT inEnds IS NULL THEN
			
				SET description=CONCAT
				(
					description,
					
					IF(inStart IS NULL,". Until "," until "),
					
					inEnds
				);
			END IF;
			
			-- and add timezone info if relevant
			
			IF (NOT inStart IS NULL OR NOT inEnds IS NULL) AND 'SYSTEM' != inTimeZone THEN
			
				SET description=CONCAT(
				
					description,
					
					CONCAT(" (",inTimeZone,")")
				);
				
			END IF;
		END IF;
		
	END IF;
	
	RETURN description;
END; ___

CREATE SQL SECURITY INVOKER VIEW `tables` AS
 SELECT `TABLE_NAME` AS `table`,
        `ENGINE` AS `Type`,
        `q`.formatInt(`TABLE_ROWS`) AS `Records`,
        `q`.formatSize(`DATA_LENGTH`) AS `Data Size`,
        `q`.formatSize(`INDEX_LENGTH`) AS `Index Size`,
        `q`.formatSize(`INDEX_LENGTH`+`DATA_LENGTH`) AS `Total Size`,
        `CREATE_TIME` AS `Created`,
        `UPDATE_TIME` AS `Updated`,
        `CHECK_TIME` AS `Checked`
 FROM `INFORMATION_SCHEMA`.`tables`
 WHERE `TABLE_SCHEMA`=SCHEMA() AND `TABLE_TYPE`='BASE TABLE'
 ORDER BY `DATA_LENGTH`+`INDEX_LENGTH` ASC,
          `TABLE_NAME` ASC;
___

CREATE SQL SECURITY INVOKER VIEW `all_tables` AS
 SELECT `TABLE_SCHEMA` AS `database`,
        `TABLE_NAME` AS `table`,
        `ENGINE` AS `Type`,
        `q`.formatInt(`TABLE_ROWS`) AS `Records`,
        `q`.formatSize(`DATA_LENGTH`) AS `Data Size`,
        `q`.formatSize(`INDEX_LENGTH`) AS `Index Size`,
        `q`.formatSize(`INDEX_LENGTH`+`DATA_LENGTH`) AS `Total Size`,
        `CREATE_TIME` AS `Created`,
        `UPDATE_TIME` AS `Updated`,
        `CHECK_TIME` AS `Checked`
 FROM `INFORMATION_SCHEMA`.`tables`
 WHERE `TABLE_TYPE`='BASE TABLE'
 ORDER BY `TABLE_SCHEMA` ASC, 
		  `DATA_LENGTH`+`INDEX_LENGTH` ASC,
          `TABLE_NAME` ASC;
___

CREATE SQL SECURITY INVOKER VIEW `users` AS
 SELECT CONCAT(`user`,'@',`host`) AS `User`, 
 CONCAT
 (
	IF(`Select_priv`='Y','S','.'),
	IF(`Insert_priv`='Y','I','.'),
	IF(`Update_priv`='Y','U','.'),
	IF(`Delete_priv`='Y','D','.'),
	IF(`Alter_priv`='Y','A','.'),
	IF(`Create_priv`='Y','C','.'),
	IF(`Execute_priv`='Y','X','.'),
	' ',
	IF(`Drop_priv`='Y','d','.'),
	IF(`Reload_priv`='Y','r','.'),
	IF(`Shutdown_priv`='Y','s','.'),
	IF(`Process_priv`='Y','p','.'),
	IF(`File_priv`='Y','f','.'),
	' <',
	IF(`Repl_slave_priv`='Y','S','.'),
	IF(`Repl_client_priv`='Y','C','.'),
	'> ',
	IF(`Show_db_priv`='Y','(*)','(.)'),
	' ',
	IF(`Super_Priv`='Y','{S}','{.}'),
	' ',
	IF(`Grant_priv`='Y','[G]','[.]')
 ) AS `Global Privileges` 
 FROM `mysql`.`user`
 ORDER BY `mysql`.`user`.`user` ASC, `mysql`.`user`.`host` ASC;
___

CREATE PROCEDURE tables( in_table_schema CHAR(200))
 COMMENT 'Shows a formatted list of all the tables in the specified database schema'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
  SET @Theschema=in_table_schema;
  SET @theQuery=CONCAT("
  SELECT `TABLE_NAME` AS `Table in ",@Theschema,"`,
        `ENGINE` AS `Type`,
        `q`.formatInt(`TABLE_ROWS`) AS `Records`,
        `q`.formatSize(`DATA_LENGTH`) AS `Data Size`,
        `q`.formatSize(`INDEX_LENGTH`) AS `Index Size`,
        `q`.formatSize(`INDEX_LENGTH`+`DATA_LENGTH`) AS `Total Size`,
        `CREATE_TIME` AS `Created`,
        `UPDATE_TIME` AS `Updated`,
        `CHECK_TIME` AS `Checked`
 FROM `INFORMATION_SCHEMA`.`tables`
 WHERE `TABLE_SCHEMA`=? AND `TABLE_TYPE`='BASE TABLE'
 ORDER BY `DATA_LENGTH`+`INDEX_LENGTH` ASC,
 `TABLE_NAME` ASC;");
 
 PREPARE stmttables FROM @theQuery;
 EXECUTE stmttables USING @Theschema;
 DEALLOCATE PREPARE stmttables;
 SET @Theschema=NULL;
 SET @theQuery=NULL;
END;
___

CREATE PROCEDURE users()
 COMMENT 'Shows a list of all available user accounts and their global privileges'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
 SELECT * FROM `q`.`users`;
END;
___
 
CREATE PROCEDURE procedures( in_schema CHAR(200) )
 COMMENT 'Shows a list of all available procedures in the specified database'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
 DECLARE theQuery TEXT DEFAULT NULL;
 SET @Theschema=in_schema;
 SET @theQuery=CONCAT('
 SELECT 
	`ROUTINE_NAME` AS `Procedure in ',@Theschema,'`,
	CONCAT
	(
		`ROUTINE_NAME`,
		"(",
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 "void"
		),
		")"
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 WHERE `routine_type`="PROCEDURE" AND `routine_schema`=?
 ORDER BY `ROUTINE_TYPE` ASC, `ROUTINE_NAME` ASC;');
 
 PREPARE stmtview FROM @theQuery;
 EXECUTE stmtview USING @Theschema;
 DEALLOCATE PREPARE stmtview;
 SET @Theschema=NULL;
 SET @theQuery=NULL; 
 
END;
___

CREATE PROCEDURE functions( in_schema CHAR(200) )
 COMMENT 'Shows a list of all available functions in the specified database'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
 DECLARE theQuery TEXT DEFAULT NULL;
 SET @Theschema=in_schema;
 SET @theQuery=CONCAT('
 SELECT 
	`ROUTINE_NAME` AS `Function in ',@Theschema,'`,
	CONCAT
	(
		IF(`DATA_TYPE`="","void",UPPER(`DATA_TYPE`))," ",
		`ROUTINE_NAME`,
		"(",
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 "void"
		),
		")"
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 WHERE `routine_type`="FUNCTION" AND `routine_schema`=?
 ORDER BY `ROUTINE_TYPE` ASC, `ROUTINE_NAME` ASC;');
 
 PREPARE stmtview FROM @theQuery;
 EXECUTE stmtview USING @Theschema;
 DEALLOCATE PREPARE stmtview;
 SET @Theschema=NULL;
 SET @theQuery=NULL; 
 
END;

CREATE PROCEDURE routines( in_routine_schema CHAR(200))
 COMMENT 'Shows a list of all available functions and procedures in the specified database'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
 DECLARE theQuery TEXT DEFAULT NULL;
 SET @Theschema=in_routine_schema;
 SET @theQuery=CONCAT('
 SELECT 
	`ROUTINE_NAME` AS `Routine in ',@Theschema,'`,
	`ROUTINE_TYPE` AS `Type`,
	CONCAT
	(
		IF(`DATA_TYPE`="","void",UPPER(`DATA_TYPE`))," ",
		`ROUTINE_NAME`,
		"(",
		COALESCE
		(
		 (
			SELECT GROUP_CONCAT(`PARAMETER_NAME`) 
			FROM `INFORMATION_SCHEMA`.`parameters` `par`
			WHERE `par`.`SPECIFIC_SCHEMA`=`rou`.`ROUTINE_SCHEMA`
			AND `par`.`SPECIFIC_NAME`=`rou`.`ROUTINE_NAME`
		 ),
		 "void"
		),
		")"
	) AS `Info`,
	`ROUTINE_COMMENT` AS `Comment`
 FROM `INFORMATION_SCHEMA`.`routines` as rou
 WHERE `routine_schema`=?
 ORDER BY `ROUTINE_TYPE` ASC, `ROUTINE_NAME` ASC;');
 
 PREPARE stmtview FROM @theQuery;
 EXECUTE stmtview USING @Theschema;
 DEALLOCATE PREPARE stmtview;
 SET @Theschema=NULL;
 SET @theQuery=NULL;
END;
___

CREATE PROCEDURE views( in_view_schema CHAR(200))
 COMMENT 'Shows a formatted list of all the tables in the specified database schema'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
 DECLARE theQuery TEXT DEFAULT NULL;
 SET @Theschema=in_view_schema;
 SET @theQuery=CONCAT("
 SELECT `TABLE_NAME` AS `View in ",@Theschema,"` 
 FROM `INFORMATION_SCHEMA`.`views`   
 WHERE `TABLE_SCHEMA`=?");
 
 PREPARE stmtview FROM @theQuery;
 EXECUTE stmtview USING @Theschema;
 DEALLOCATE PREPARE stmtview;
 SET @Theschema=NULL;
 SET @theQuery=NULL;
END;
___

CREATE PROCEDURE events ( in_event_schema CHAR(200))
 COMMENT 'Shows a formatted list of all the events in the specified database schema'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
 DECLARE theQuery TEXT DEFAULT NULL;
 SET @Theschema=in_event_schema;
 SET @theQuery=CONCAT("
  SELECT `EVENT_NAME` AS `Event in ",@Theschema,"`,
   REPLACE(REPLACE(`STATUS`,'DISABLED','Disabled'),'ENABLED','Enabled') AS `Status`,
	`q`.`formatEventTime`(`TIME_ZONE`,`EXECUTE_AT`,`STARTS`,`ENDS`,`INTERVAL_VALUE`,`INTERVAL_FIELD`) AS `Lifetime`,
  COALESCE(`LAST_EXECUTED`,'Never') AS `Last run`
  FROM `INFORMATION_SCHEMA`.`EVENTS`
  WHERE `EVENT_SCHEMA`=?;
 ");
 PREPARE stmtview FROM @theQuery;
 EXECUTE stmtview USING @Theschema;
 DEALLOCATE PREPARE stmtview;
 SET @Theschema=NULL;
 SET @theQuery=NULL;
END;
___

CREATE PROCEDURE all_events ()
 COMMENT 'Shows a formatted list of all events across all database schemas'
  LANGUAGE SQL
   READS SQL DATA
    NOT DETERMINISTIC
     SQL SECURITY INVOKER
BEGIN
	SELECT * FROM `q`.`all_events`;
END;
___

CREATE SQL SECURITY INVOKER VIEW `all_events` AS
 SELECT `EVENT_SCHEMA` AS `Database`,
        `EVENT_NAME` AS `Event`,
        REPLACE(REPLACE(`STATUS`,'DISABLED','Disabled'),'ENABLED','Enabled') AS `Status`,
        `q`.`formatEventTime`(`TIME_ZONE`,`EXECUTE_AT`,`STARTS`,`ENDS`,`INTERVAL_VALUE`,`INTERVAL_FIELD`) AS `Lifetime`,
        COALESCE(`LAST_EXECUTED`,'Never') AS `Last run`
 FROM `INFORMATION_SCHEMA`.`EVENTS` 
 ORDER BY `EVENT_SCHEMA` ASC
;___

CREATE SQL SECURITY INVOKER VIEW `events` AS
 SELECT `EVENT_NAME` AS `Event`,
        REPLACE(REPLACE(`STATUS`,'DISABLED','Disabled'),'ENABLED','Enabled') AS `Status`,
        `q`.`formatEventTime`(`TIME_ZONE`,`EXECUTE_AT`,`STARTS`,`ENDS`,`INTERVAL_VALUE`,`INTERVAL_FIELD`) AS `Lifetime`,
        COALESCE(`LAST_EXECUTED`,'Never') AS `Last run`
 FROM `INFORMATION_SCHEMA`.`EVENTS`
 WHERE `EVENT_SCHEMA`=SCHEMA()
;___


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