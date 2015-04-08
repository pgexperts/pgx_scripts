create or replace function kill_idle_transactions (
    timelimit INTERVAL DEFAULT '10 minutes',
    safe_users TEXT[] DEFAULT '{}')
returns SETOF json
language plpgsql
as
$f$
declare
    cancelled JSON;
    
begin

    FOR cancelled IN
        WITH terminated AS (
            SELECT pg_stat_activity.*, pg_terminate_backend(pid)
            FROM pg_stat_activity
            WHERE state = 'idle in transaction'
              AND (now() - state_change) > timelimit
              AND ( usename != ANY(safe_users)
                    OR safe_users = '{}' )),
        termformat AS (
            SELECT now() as killtime,
                datname, pid, usename, application_name,
                client_addr, backend_start, xact_start,
                state_change, waiting, "query"
            FROM terminated )
        SELECT row_to_json(termformat.*)
        FROM termformat
        LOOP
        
        RETURN NEXT cancelled;

    END LOOP;

    RETURN;

end; $f$;

