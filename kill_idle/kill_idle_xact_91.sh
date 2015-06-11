#!/bin/bash

# please configure by setting the folloiwng shell variables

# REQUIRED: set location of log file for logging killed transactions
LOGFILE=/var/log/postgresql/kill_idle.log

# REQUIRED: set timelimit for oldest idle transaction, in minutes
IDLETIME=15

# REQUIRED: set timelimit for oldest non-idle long-running transaction
# in minutes.  Set to 1000 if you don't really want these cancelled
XACTTIME=120

# REQUIRED: set users to be ignored and not kill idle transactions
# generally you want to omit the postgres superuser and the user
# pg_dump runs as from being killed
# if you have no users like this, just set both to XXXXX
SUPERUSER=postgres
BACKUPUSER=XXXXX

# REQUIRED: path to psql, since cron often lacks search paths
PSQL=/usr/lib/postgresql/9.1/bin/psql

# OPTIONAL: set these connection variables.  if you are running as the
# postgres user on the local machine with passwordless login, you will 
# not needto set any of these
PGHOST=
PGUSER=
PGPORT=
PGPASSWORD=

# you should not need to change code below this line
####################################################

export PGHOST
export PGUSER
export PGPORT
export PGPASSWORD
exec >> $LOGFILE 2>&1
SAFELIST="ARRAY['${SUPERUSER}', '${BACKUPUSER}']"
IDLEPARAM="'${IDLETIME} minutes'"
XACTPARAM="'${XACTTIME} minutes'"

KILLQUERY="WITH idles AS (
    SELECT datname, procpid, usename, application_name,
        client_addr, backend_start, xact_start, query_start,
        waiting, pg_terminate_backend(procpid)
    FROM pg_stat_activity
    WHERE current_query = '<IDLE> in transaction'
        AND usename != '${SUPERUSER}'
        AND usename != '${BACKUPUSER}'
        AND ( ( now() - xact_start ) > '${XACTTIME} minutes'
            OR ( now() - query_start ) > '${IDLETIME} minutes' )
)
SELECT array_to_string(ARRAY[ now()::TEXT,
                idles.datname::TEXT, idles.procpid::TEXT, idles.usename::TEXT,
                idles.application_name, idles.client_addr::TEXT,
                idles.backend_start::TEXT, idles.xact_start::TEXT,
                idles.query_start::TEXT, idles.waiting::TEXT], '|')
FROM idles
ORDER BY xact_start;"

$PSQL -q -t -c "${KILLQUERY}"

exit 0

