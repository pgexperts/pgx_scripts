Lock-Logging Scripts
====================

Since the amount of information you can usefully get out of log_lock_waits is limited, these 
scripts add a way to log complex information to PostgreSQL tables.

Run the script as follows:

    ./log_locks.sh INTERVAL XNUMBER

INTERVAL: number of seconds at which to repeat the logging
XNUMBER: number of times to poll the locks

So for example, to log every 30 seconds for 1 hour, you'd do:

    ./log_locks.sh 30 120
    
This script can be terminated using ctrl-C or kill without consequences.
    
This produces two logs in the current directory, lock_table.log and lock_transaction.log.  These
logs can be loaded into a database using the table definitions in lock_tables.sql.  If you run the
script more than once, new output will be appended to those files.

Note that, under pathological conditions, querying the locks tables can have significant overhead,
and the lock logging query itself can become blocked or bog down.  For that reason, we recommend
discretion on how frequently you poll the locks.  Polling locks more often than every 10 seconds
is never recommended.

**Requires PostgreSQL 9.2 or Later**