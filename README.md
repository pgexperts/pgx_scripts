pgx_scripts
===========

A collection of useful little scripts for database analysis and administration, created by our team at PostgreSQL Experts.

bloat
=====

Queries to estimate bloat in tables and indexes.

index_bloat_check.sql
---------------------

An overhauled index bloat check.  Lists indexes which are likely to be bloated and estimates bloat amounts.  Requires PostgreSQL > 8.4, superuser access, and a 64-bit compile.  Only works for BTree indexes, not GIN, GiST, or more exotic indexes.  Still needs cleanup.

table_bloat_check.sql
---------------------

An overhauled table bloat check.  Lists tables which are likely to be bloated and estimates bloat amounts.  Requires PostgreSQL >= 8.4 and a 64-bit compile.  Cannot estimate bloat for tables containing types with no stats functions (such as original JSON).

no_stats_table_check.sql
------------------------

Query to list all tables which have "no stats" columns and thus can't be estimated.


kill_idle
=========

kill_idle_91.sql
----------------

A stored procedure which kills idle transactions on PostgreSQL versions 8.3 to 9.1.  Intended to be called by a cron job.  Takes idle time, polling time, and exempted user list parameters.  Outputs pipe-delimited text with the data about the sessions killed.

kill_idle_93.sql
----------------

A stored procedure which kills idle transactions on PostgreSQL versions 9.2 and later.  Intended to be called by a cron job.  Takes idle time and exempted user list parameters.  Outputs JSON with the data about the sessions killed.

Indexes
=======

Various queries to introspect index usage.

fk_no_index.sql
---------------

Queries for foreign keys with no index on the referencing side.  Note that you don't always want indexes on the referencing side, but this helps you decide if you do.

duplicate_indexes_fuzzy.sql
---------------------------

Check indexes and looks at whether or not they are potentially duplicates.  It does this by checking the columns used by each index, so it reports lots of false duplicates for partial and functional indexes.

Locks
=====

Tools and a set of queries to analyze lock-blocking.

transaction_locks.sql
---------------------

Requires: Postgres 9.2+

Lists waiting transaction locks and what they're waiting on, if possible.
Includes relation and query information, but realistically needs to be
accompanied by full query logging to be useful.  Needs to be run
per active database.

table_locks.sql
---------------

Lists direct locks on tables which conflict with locks held by other sessions.  Note that table
locks are often short-lived, and as a result this will often result in zero rows.


Additional Contributors
=======================

In addition to the staff of PostgreSQL Experts, we are indebted
to:

* The authors of the check_postgres.pl script, especially 
  Greg Sabino Mulainne, for supplying the
  original bloat queries on which our bloat queries are based.
* Andrew Gierth for help on various system queries.
* ioguix for collaborating on bloat calculation math.