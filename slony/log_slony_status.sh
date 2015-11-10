#!/bin/bash

# simple script to log transaction locks to a table
# assumes that you're running it as the postgres user and don't need a password

# set interval and number of executions
# interval is set in seconds
# defaults to 1000 minutes once per minute
# not recommended to run this more than 4X per minute
INTERVAL=${1:-60}
XNUMBER=${2:-1000}

# change to path of psql
PSQL='psql'

# database and slony schema you're targeting
DBNAME='postgres'
SLSCHEMA='_slony'

# modify if required
# statement timeout is required to keep the lock query
# from hanging
DBPORT=''
DBHOST=''
STATTIMEOUT=2000
SUPER="postgres"

# output files. you shouldn't need to modify these
# unless you're doing something special
LOG="slony_stats.log"

# queries; you should not need to modify these
SLQUERY="
SELECT now() as log_ts,
    current_database() as dbname,
    sl_status.*, 
    (SELECT count(*) FROM ${SLSCHEMA}.sl_log_1) as log_1_count,
    (SELECT count(*) FROM ${SLSCHEMA}.sl_log_2) as log_2_count
FROM ${SLSCHEMA}.sl_status;
"

# write headers
if [ ! -f $LOG ]; then
    echo '' > $TABLELOG
fi

if [ ! -f XTNLOG ]; then
    echo 'log_ts|dbname|st_origin|st_received|st_last_event|st_last_event_ts|st_last_received|st_last_received_ts|st_last_received_event_ts|st_lag_num_events|st_lag_time|log_1_count|log_2_count' > $LOG
fi
                  
for ((i=0; i<$XNUMBER; i++)); do
                    
    $PSQL -A -q -t -c "SET STATEMENT_TIMEOUT=${STATTIMEOUT}; ${SLQUERY}" -U $SUPER $DBNAME $DBPORT $DBHOST >> $LOG
    
    if (($i%10==0)); then
        echo "slony polled $i times"
    fi
    
    sleep $INTERVAL
    
done

exit 0
