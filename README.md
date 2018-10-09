# mysql-qtools
**mysql_tools** are a suite of tools aimed at improving commandline client usability and ergonomics. 

All of the tools are in the form of a view, function, or procedure, all stored in the `q` database.

The name of the database has been chosen to be as short as possible and as unique as possible. 

The primary intended use case is for a human to type in the view, procedure, or function on the MySQL commandline client. In other words, the focus is on making things human readable. 

All tools are created with `SQL SECURITY INVOKER` so as not to leak any information or functionality to unauthorised accounts. 

Most of the views are meant to be used without switching to the `q` database, and many of the views also have a procedural version.

E.g. to get a human readable formatted list of tables whilst in the `test` database:

```SQL
SELECT * FROM q.tables;
```

Is equivalent to

```SQL
CALL q.tables('test');
```

## Installing ##

```SQL
source /tmp/qtools.sql
```
