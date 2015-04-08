Lock-Logging Scripts
====================

Since the amount of information you can usefully get out of log_lock_waits is limited, these 
scripts add a way to log complex information to PostgreSQL tables.

1. Run table_locks_setup.sql and transaction_locks_setup.sql against the target database
   This will create 2 tables and 2 functions for logging.

2. Add a cron job to execute log_locks.sh every 1 to 10 minutes.  

Note that, under pathological conditions, querying the locks tables can have significant overhead,
and the lock logging query itself can become blocked or bog down.  For that reason, we recommend
discretion on how frequently you run the cron job.

**Requires PostgreSQL 9.2 or Later**