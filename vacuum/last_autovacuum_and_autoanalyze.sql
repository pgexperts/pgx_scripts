-- Show last autovacuum and autoanalyze by table size descending.
SELECT pg_class.relname
     , pg_namespace.nspname
     , pg_size_pretty(pg_total_relation_size(pg_class.oid))
     , 
       CASE
        WHEN COALESCE(last_vacuum,'1/1/1000')  >
         COALESCE(last_autovacuum,'1/1/1000') THEN
         pg_stat_all_tables.last_vacuum
       ELSE last_autovacuum
       END AS last_vacuumed
     , 
       CASE
        WHEN COALESCE(last_analyze,'1/1/1000') >
        COALESCE(last_autoanalyze,'1/1/1000') THEN
        pg_stat_all_tables.last_analyze
       ELSE last_autoanalyze
       END AS last_analyzed
     , pg_relation_size(pg_class.oid)
  FROM pg_class
  JOIN pg_namespace
    ON pg_class.relnamespace                  = pg_namespace.oid
  JOIN pg_stat_all_tables
    ON (
        pg_class.relname                       = pg_stat_all_tables.relname
   AND pg_namespace.nspname                   = pg_stat_all_tables.schemaname
       )
 WHERE pg_namespace.nspname NOT IN ('pg_toast')
 ORDER BY pg_relation_size(pg_class.oid) DESC ;
