#!/bin/bash

# this verson of kill idle works on versions 9.2 and later.

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
PSQL=/usr/lib/postgresql/9.3/bin/psql

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
    SELECT now() as run_at, datname, pid, usename, application_name,
        client_addr, backend_start, xact_start, state_change,
        waiting, regexp_replace(substr(query, 1, 100), E$$[\n\r]+$$, ' ', 'g' ) as query,
        pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE state = 'idle in transaction'
        AND usename != '${SUPERUSER}'
        AND usename != '${BACKUPUSER}'
        AND ( ( now() - xact_start ) > '${XACTTIME} minutes'
            OR ( now() - state_change ) > '${IDLETIME} minutes' )
) 
SELECT row_to_json(idles.*)
FROM idles
ORDER BY xact_start;"

$PSQL -q -t -c "${KILLQUERY}"

exit 0

