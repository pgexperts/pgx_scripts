#!/bin/bash

# simple script to log transaction locks to a table
# assumes that you're running it as the postgres user and don't need a password

# change to path of psql
PSQL='/usr/pgsql-9.2/bin/psql'

# list all databases you're targeting, space separated
DBNAMES='postgres mydatabase'

# modify if required
DBPORT=''
DBHOST=''

for DBNAME in $DBNAMES; do
  $PSQL -c "SELECT log_transaction_locks();" -U postgres $DBNAME $DBPORT $DBHOST
  $PSQL -c "SELECT log_table_locks();" -U postgres $DBNAME $DBPORT $DBHOST
done

# $PSQL -c "INSERT INTO activity_log SELECT * FROM pg_stat_activity;" -U postgres $DBNAME $DBPORT $DBHOST

exit 0
