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

--- To uninstall mysql-qtools:
--- From your MySQL console execute
--- source /path/qtools-uninstall.sql
---
--- Alternatively if your MySQL server only allows sourcing from
--- specific directories, you can try 
---
--- mysql [options] < /path/qtools-uninstall.sql
SELECT 'Uninstalling mysql-qtools' AS `Info`;
DROP DATABASE IF EXISTS `q`;
SELECT 'mysql-qtools has been uninstalled' AS `Info`;