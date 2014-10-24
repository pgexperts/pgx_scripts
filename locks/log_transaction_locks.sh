#!/bin/bash

# simple script to log transaction locks to a table
# assumes that you're running it as the postgres user and don't need a password

# change to path of psql
PSQL='/usr/lib/postgresql/9.3/bin/psql'

# change to database you're targeting
DBNAME='somedb'

# modify if required
DBPORT='-p 5432'
DBHOST='-h 127.0.0.1'

$PSQL -c "INSERT INTO log_transaction_locks SELECT * FROM log_transaction_locks_view" -U postgres $DBNAME $DBPORT $DBHOST

exit 0