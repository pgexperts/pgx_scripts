-- query to analyze waiting transaction locks
-- requires Postgres 9.2 or greater

WITH table_locks AS (
    select pid,
    relation::regclass as lockobj,
    case when page is not null and tuple is not null then
        mode || ' on ' || page::text || ':' || tuple::text
    else
        mode
    end as lock_mode,
    locktype
    from pg_locks
        join pg_database
            ON pg_locks.database = pg_database.oid
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
    from pg_locks
    where locktype = 'transactionid'
    union all
    select pid, virtualxid::text as lxid, granted
    from pg_locks
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
            AND waiting_proc.datname = current_database()
    LEFT OUTER JOIN txn_granted
        ON txn_waiting.lxid = txn_granted.lxid
    LEFT OUTER JOIN pg_stat_activity as locked_proc
        ON txn_granted.pid = locked_proc.pid
    LEFT OUTER JOIN locked_list AS waiting_locks
        ON txn_waiting.pid = waiting_locks.pid
    LEFT OUTER JOIN locked_list AS locked_locks
        ON txn_granted.pid = locked_locks.pid
order by waiting_pid;
    
