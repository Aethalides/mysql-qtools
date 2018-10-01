# mysql-qtools
A database with tools to use when exploring MySQL via its commandline client

## Installing ##

```SQL
source /tmp/qtools.sql
```

All tools are used without switching to the q database. E.g. to view a list of views in the current database:

```SQL
SELECT * FROM q.views;
```

You can find out the version with 

```SQL
SELECT * FROM q.version;
```

And get help with 

```SQL
SELECT * FROM q.help
```

Alternatively you can use the CALL syntax for these 2:

```SQL
CALL q.version;
CALL q.help;
```
