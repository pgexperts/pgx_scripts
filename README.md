pgx_scripts
===========

A collection of useful little scripts for database analysis and administration, created by our team at PostgreSQL Experts.

administration
==============

kill_idle_91.sql
----------------

A stored procedure which kills idle transactions on PostgreSQL versions 8.3 to 9.1.  Intended to be called by a cron job.  Takes idle time, polling time, and exempted user list parameters.  Outputs pipe-delimited text with the data about the sessions killed.

kill_idle_93.sql
----------------

A stored procedure which kills idle transactions on PostgreSQL versions 9.2 and later.  Intended to be called by a cron job.  Takes idle time and exempted user list parameters.  Outputs JSON with the data about the sessions killed.