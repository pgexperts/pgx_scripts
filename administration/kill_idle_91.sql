create or replace function kill_idle_transactions_91 (
    timelimit INTERVAL DEFAULT '10 minutes',
    safe_users TEXT[] DEFAULT '{}',
    wait_time INT DEFAULT 10)
returns SETOF text
language plpgsql
as
$f$
declare idles INT[];
    cancelled RECORD;
    output TEXT;
    
begin

    SELECT array_agg(procpid)
    INTO idles
    FROM pg_stat_activity
    WHERE current_query = '<IDLE> in transaction'
    AND ( now() - xact_start ) > timelimit
        AND ( usename != ANY(safe_users)
            OR safe_users = '{}' );

    IF idles IS NULL THEN
        RETURN;
    END IF;
    
    PERFORM pg_sleep(wait_time);

    FOR cancelled IN
            SELECT pg_stat_activity.*, pg_terminate_backend(procpid)
            FROM pg_stat_activity
            WHERE procpid = ANY ( idles )
            AND current_query = '<IDLE> in transaction' LOOP

        output := array_to_string(ARRAY[ now()::TEXT,
                cancelled.datname::TEXT, cancelled.procpid::TEXT, cancelled.usename::TEXT,
                cancelled.application_name, cancelled.client_addr::TEXT,
                cancelled.backend_start::TEXT, cancelled.xact_start::TEXT,
                cancelled.waiting::TEXT], '|');

        RETURN NEXT output;

    END LOOP;

    RETURN;

end; $f$;