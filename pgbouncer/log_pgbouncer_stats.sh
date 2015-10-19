#!/bin/bash

# take number of minutes as parameter; otherwise
# run for 1 hour
NUMMIN=${1:-60}
NUMMIN=$(($NUMMIN * 2 + 10))
CURMIN=0

export PGUSER=pgbouncer
export PGPASSWORD=
export PGHOST=127.0.0.1
export PGDATABASE=pgbouncer

adddate() {
    DTSTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    while IFS= read -r line; do
        echo "$DTSTAMP|$line"
    done
}

while [ $CURMIN -lt $NUMMIN  ] 
do

    psql -q -A -t -c "show pools" | adddate >> pools.log
    
    psql -q -A -t -c "show stats" | adddate >> stats.log
    
    psql -q -A -t -c "show clients" | adddate >> clients.log

    #cycle twice per minute
    sleep 30
    let CURMIN=CURMIN+1 
 
done

exit 0