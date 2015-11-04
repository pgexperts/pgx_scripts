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

# list all databases you're targeting, space separated
DBNAMES='postgres flo'

# modify if required
# statement timeout is required to keep the lock query
# from hanging
DBPORT=''
DBHOST=''
STATTIMEOUT=2000
SUPER="josh"

# output files. you shouldn't need to modify these
# unless you're doing something special
TABLELOG='lock_table.log'
XTNLOG='lock_transaction.log'

# queries; you should not need to modify these
TABLEQUERY="WITH table_locks AS (
                select pid,
                relation::int as relation,
                (relation::regclass)::text as locked_relation,
                mode,
                page || ':' || tuple as locked_tuple,
                locktype,
                coalesce(transactionid::text, virtualxid) as lxid,
                granted
                from pg_locks
                    join pg_database
                        ON pg_locks.database = pg_database.oid
                where relation is not null
                    and pg_database.datname = current_database()
                    and locktype IN ( 'relation', 'extend', 'page', 'tuple' )
            ),
            lock_granted AS (
                select * from table_locks
                where granted
            ),
            lock_waiting AS (
                select * from table_locks
                where not granted
            )
            select now() as lock_ts,
                current_database() as dbname,
                lock_waiting.pid as waiting_pid,
                lock_waiting.lxid as wait_xid,
                lock_granted.pid as locked_pid,
                lock_granted.lxid as locked_xid,
                lock_granted.locked_relation,
                lock_waiting.locktype as waiting_type,
                lock_waiting.mode as waiting_mode,
                lock_waiting.locked_tuple as tuple_waiting,
                lock_granted.locktype as locked_type,
                lock_granted.mode as lock_mode,
                lock_granted.locked_tuple as tuple_locked,
                waiting_proc.application_name as waiting_app,
                waiting_proc.client_addr as waiting_addr,
                waiting_proc.xact_start as waiting_xact_start,
                waiting_proc.query_start as waiting_query_start,
                waiting_proc.state_change as waiting_start,
                waiting_proc.query as waiting_query,
                locked_proc.application_name as locked_app,
                locked_proc.client_addr as locked_addr,
                locked_proc.xact_start as locked_xact_start,
                locked_proc.query_start as locked_query_start,
                locked_proc.state as locked_state,
                locked_proc.state_change as locked_state_start,
                locked_proc.query as locked_last_query
            from lock_waiting
                JOIN pg_stat_activity as waiting_proc
                    ON lock_waiting.pid = waiting_proc.pid
                LEFT OUTER JOIN lock_granted
                    ON lock_waiting.relation = lock_granted.relation
                LEFT OUTER JOIN pg_stat_activity as locked_proc
                    ON lock_granted.pid = locked_proc.pid
            order by locked_pid, locked_relation;"
            
XTNQUERY="WITH mylocks AS (
            SELECT * FROM pg_locks
            WHERE locktype IN ( 'transactionid', 'virtualxid' )
        ),
        table_locks AS (
            select pid,
            (relation::regclass)::TEXT as lockobj,
            case when page is not null and tuple is not null then
                mode || ' on ' || page::text || ':' || tuple::text
            else
                mode
            end as lock_mode,
            locktype
            from mylocks
                join pg_database
                    ON mylocks.database = pg_database.oid
            where relation is not null
                and pg_database.datname = current_database()
            order by lockobj
        ),
        locked_list AS (
            select pid,
            array_agg(lockobj) as lock_relations,
            array_agg(lock_mode) as lock_modes,
            array_agg(locktype) as lock_types
            from table_locks
            group by pid
        ),
        txn_locks AS (
            select pid, transactionid::text as lxid, granted
            from mylocks
            where locktype = 'transactionid'
            union all
            select pid, virtualxid::text as lxid, granted
            from mylocks
            where locktype = 'virtualxid'
        ),
        txn_granted AS (
            select pid, lxid from txn_locks
            where granted
        ),
        txn_waiting AS (
            select pid, lxid from txn_locks
            where not granted
        )
        select now() as lock_ts,
                current_database() AS dbname,
                txn_waiting.pid as waiting_pid,
                txn_waiting.lxid as wait_xid,
                txn_granted.pid as locked_pid,
                waiting_proc.application_name as waiting_app,
                waiting_proc.client_addr as waiting_addr,
                waiting_proc.xact_start as waiting_xact_start,
                waiting_proc.query_start as waiting_query_start,
                waiting_proc.state_change as waiting_start,
                waiting_proc.query as waiting_query,
                locked_proc.application_name as locked_app,
                locked_proc.client_addr as locked_addr,
                locked_proc.xact_start as locked_xact_start,
                locked_proc.query_start as locked_query_start,
                locked_proc.state as locked_state,
                locked_proc.state_change as locked_state_start,
                locked_proc.query as locked_last_query,
                waiting_locks.lock_relations as waiting_relations,
                waiting_locks.lock_modes as waiting_modes,
                waiting_locks.lock_types as waiting_lock_types,
                locked_locks.lock_relations as locked_relations,
                locked_locks.lock_modes as locked_modes,
                locked_locks.lock_types as locked_lock_types
            from txn_waiting
                JOIN pg_stat_activity as waiting_proc
                    ON txn_waiting.pid = waiting_proc.pid
                LEFT OUTER JOIN txn_granted
                    ON txn_waiting.lxid = txn_granted.lxid
                LEFT OUTER JOIN pg_stat_activity as locked_proc
                    ON txn_granted.pid = locked_proc.pid
                LEFT OUTER JOIN locked_list AS waiting_locks
                    ON txn_waiting.pid = waiting_locks.pid
                LEFT OUTER JOIN locked_list AS locked_locks
                    ON txn_granted.pid = locked_locks.pid;"

# write headers
if [ ! -f $TABLELOG ]; then
    echo 'lock_ts|dbname|waiting_pid|wait_xid|locked_pid|locked_xid|locked_relation|waiting_type|waiting_mode|waiting_tuple|locked_type|locked_mode|locked_tuple|waiting_app|waiting_addr|waiting_xact_start|waiting_query_start|waiting_start|waiting_query|locked_app|locked_addr|locked_xact_start|locked_query_start|locked_state|locked_state_start|locked_last_query' > $TABLELOG
fi

if [ ! -f XTNLOG ]; then
    echo 'lock_ts|dbname|waiting_pid|waiting_xid|locked_pid|waiting_app|waiting_addr|waiting_xact_start|waiting_query_start|waiting_start|waiting_query|locked_app|locked_addr|locked_xact_start|locked_query_start|locked_state|locked_state_start|locked_last_query|waiting_relations|waiting_modes|waiting_lock_types|locked_relations|locked_modes|locked_lock_types' > $XTNLOG
fi
                  
for ((i=0; i<$XNUMBER; i++)); do
                    
    for DBNAME in $DBNAMES; do
        $PSQL -A -q -t -c "SET STATEMENT_TIMEOUT=${STATTIMEOUT}; ${TABLEQUERY}" -U $SUPER $DBNAME $DBPORT $DBHOST >> $TABLELOG
        $PSQL -A -q -t -c "SET STATEMENT_TIMEOUT=${STATTIMEOUT}; ${XTNQUERY}" -U $SUPER $DBNAME $DBPORT $DBHOST >> $XTNLOG
    done
    
    if (($i%10==0)); then
        echo "locks polled $i times"
    fi
    
    sleep $INTERVAL
    
done

exit 0
