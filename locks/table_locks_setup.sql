-- do statement to set things up for transaction lock logging
-- written so that it can be run repeatedly

DO $d$
BEGIN
    PERFORM 1
    FROM pg_stat_user_tables
    WHERE relname = 'log_table_locks';

    IF NOT FOUND THEN

        CREATE TABLE log_table_locks (
            lock_ts TIMESTAMPTZ,
            waiting_pid INT,
            wait_xid TEXT,
            locked_pid INT,
            locked_xid TEXT,
            locked_relation TEXT,
            waiting_type TEXT,
            waiting_mode TEXT,
            waiting_tuple TEXT,
            locked_type TEXT,
            locked_mode TEXT,
            locked_tuple TEXT,
            waiting_app TEXT,
            waiting_addr TEXT,
            waiting_xact_start TIMESTAMPTZ,
            waiting_query_start TIMESTAMPTZ,
            waiting_start TIMESTAMPTZ,
            waiting_query TEXT,
            locked_app TEXT,
            locked_addr TEXT,
            locked_xact_start TIMESTAMPTZ,
            locked_query_start TIMESTAMPTZ,
            locked_state TEXT,
            locked_state_start TIMESTAMPTZ,
            locked_last_query TEXT
        );

        CREATE OR REPLACE FUNCTION log_table_locks()
        RETURNS BIGINT
        LANGUAGE sql
        SET statement_timeout = '2s'
        --SET search_path = pgx
        AS $f$
            WITH table_locks AS (
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
            ),
            inserter as (
            INSERT INTO log_table_locks
            select now() as lock_ts,
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
            order by locked_pid, locked_relation
            returning waiting_pid
            )
            SELECT count(*)
            FROM inserter;
        $f$;

    END IF;
END;
$d$;