#!/bin/bash

# simple script to log transaction locks to a table
# assumes that you're running it as the postgres user and don't need a password

# change to path of psql
#PSQL='/usr/lib/postgresql/9.3/bin/psql'
PSQL=/usr/bin/psql

# change to databases you're targeting
DBNAMES='mart otherdb yetanotherdb'

# modify if required
DBPORT='-p 5432'
#DBHOST='-h 127.0.0.1'
DBHOST=''

for DB in $DBNAMES ; do
  $PSQL -c "INSERT INTO log_transaction_locks SELECT * FROM log_transaction_locks_view" -U postgres $DB $DBPORT $DBHOST
  # su - postgres -c "$PSQL -c 'INSERT INTO log_transaction_locks SELECT * FROM log_transaction_locks_view' -U postgres $DB $DBPORT $DBHOST"
done

exit 0
