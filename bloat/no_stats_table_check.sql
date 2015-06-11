-- no stats query
-- to display tables/columns which are without stats
-- so we can't estimate bloat
SELECT table_schema, table_name,
    ( pg_class.relpages = 0 ) AS is_empty,
    ( psut.relname IS NULL OR ( psut.last_analyze IS NULL and psut.last_autoanalyze IS NULL ) ) AS never_analyzed,
    array_agg(column_name::TEXT) as no_stats_columns
FROM information_schema.columns
    JOIN pg_class ON columns.table_name = pg_class.relname
        AND pg_class.relkind = 'r'
    JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        AND nspname = table_schema
    LEFT OUTER JOIN pg_stats
    ON table_schema = pg_stats.schemaname
        AND table_name = pg_stats.tablename
        AND column_name = pg_stats.attname
    LEFT OUTER JOIN pg_stat_user_tables AS psut
        ON table_schema = psut.schemaname
        AND table_name = psut.relname
WHERE pg_stats.attname IS NULL
    AND table_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY table_schema, table_name, relpages, psut.relname, last_analyze, last_autoanalyze;