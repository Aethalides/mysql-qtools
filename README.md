# Contents #

[TOC]

# Introduction#

mysql-qtools are a set of views, functions, and procedures to improve the life of the DBA using the MySQL command-line client. It includes handy tools for viewing detailed information on tables, views, routines, events, processes, users, etc, all with a minimum of typing.

# Installing #

Fire up your MySQl command-line client, connect to the database server onto which you want to install the qtools, and issue the following command (providing you have saved the qtools.sql file to /tmp)

```mysql
source /tmp/qtools.sql
```

# User manual

## The basics

There are usually several variants of each tool. For instance to view a list of all the views defined in the currently selected schema (e.g. if you have selected the test database):

```SQL
SELECT * FROM q.views;
```

This is equivalent to calling the procedural variant:

```sql
CALL q.views('test');
```

In many cases there is also a `all_` variant:

```mysql
CALL q.all_views;
-- or
SELECT * FROM q.all_views;
```

You can find out the version of qtools with 

```mysql
SELECT * FROM q.version;
-- or
CALL q.version;
```

And get help with 

```SQL
SELECT * FROM q.help
```

## Available tools

### views, all_views

Shows a flat list of all the views in the currently selected database schema, or from all database schemas

```mysql
[localhost]: (Andy@localhost) [test]> select * from q.views;
+---------+
| Views   |
+---------+
| example |
+---------+
1 row in set (0.00 sec)

[localhost]: (Andy@localhost) [test]> call q.views('test');
+--------------+
| View in test |
+--------------+
| example      |
+--------------+
1 row in set (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

[localhost]: (Andy@localhost) [test]> call q.all_views;
+--------------------+------------------------------+
| Database           | View                         |
+--------------------+------------------------------+
| q                  | all_events                   |
| q                  | tables                       |
| q                  | views                        |
| q                  | version                      |
| q                  | routines                     |
| q                  | procedures                   |
| q                  | help                         |
| q                  | functions                    |
| q                  | events                       |
| q                  | all_views                    |
| q                  | all_tables                   |
| q                  | all_routines                 |
| q                  | all_procedures               |
| q                  | all_functions                |
| test               | example                      |
+--------------------+------------------------------+
15 rows in set (0.02 sec)

Query OK, 0 rows affected (0.02 sec)
```

### users

Shows a list of all the user accounts available on the server as well as a selection of their global privileges.

The privileges shown are put in shorthand:

```mysql
[localhost]: (Andy@localhost) [test]> select * from users;
+-------------------------------------+--------------------------+
| User                                | Global Privileges        |
+-------------------------------------+--------------------------+
| test@localhost                      | S..... ..... (.) {.} [.] |
| example@example.com                 | SIUDAC drspf (*) {S} [.] |
| Andy@localhost                      | SIUDAC drspf (*) {S} [G] |
+-------------------------------------+--------------------------+
```

Privileges are printed in 5 columns. The first column will put a letter in upper case for each user that has the corresponding privilege: 

**S**elect, **I**nsert, **U**pdate, **D**elete, **A**lter, **C**reate.

The second column will print a letter in lower case for the corresponding privilege:

**d**rop, **r**eload, **s**hutdown, **p**rocess, **f**ile

The third column, between parens, will print an asterisk if the user has the `show all databases` privilege, or a dot if they don't.

The fourth colum shows an `S` in between curly braces if the Super privilege is set, or a dot if it isn't.

Finally in the fifth column a `G` is printed inside square brackets for those accounts that have a `GRANT OPTION`, or a dot for those that are without this privilege.

