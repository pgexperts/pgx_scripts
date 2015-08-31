WITH 
index_usage AS (
    SELECT  sut.relid,
            current_database() AS database,
            sut.schemaname::text as schema_name, 
            sut.relname::text AS table_name,
            sut.seq_scan as table_scans,
            sut.idx_scan as index_scans,
            pg_total_relation_size(relid) as table_bytes,
            round((sut.n_tup_ins + sut.n_tup_del + sut.n_tup_upd + sut.n_tup_hot_upd) / 
                (seq_tup_read::NUMERIC + 2), 2) as writes_per_scan
    FROM pg_stat_user_tables sut
),
index_counts AS (
    SELECT sut.relid,
        count(*) as index_count
    FROM pg_stat_user_tables sut LEFT OUTER JOIN pg_indexes
    ON sut.schemaname = pg_indexes.schemaname AND
        sut.relname = pg_indexes.tablename
    GROUP BY relid
),
too_many_tablescans AS (
    SELECT 'many table scans'::TEXT as reason, 
        database, schema_name, table_name,
        table_scans, pg_size_pretty(table_bytes) as table_size,
        writes_per_scan, index_count, table_bytes
    FROM index_usage JOIN index_counts USING ( relid )
    WHERE table_scans > 1000
        AND table_scans > ( index_scans * 2 )
        AND table_bytes > 32000000
        AND writes_per_scan < ( 1.0 )
    ORDER BY table_scans DESC
),
scans_no_index AS (
    SELECT 'scans, few indexes'::TEXT as reason,
        database, schema_name, table_name,
        table_scans, pg_size_pretty(table_bytes) as table_size,
        writes_per_scan, index_count, table_bytes
    FROM index_usage JOIN index_counts USING ( relid )
    WHERE table_scans > 100
        AND table_scans > ( index_scans )
        AND index_count < 2
        AND table_bytes > 32000000   
        AND writes_per_scan < ( 1.0 )
    ORDER BY table_scans DESC
),
big_tables_with_scans AS (
    SELECT 'big table scans'::TEXT as reason,
        database, schema_name, table_name,
        table_scans, pg_size_pretty(table_bytes) as table_size,
        writes_per_scan, index_count, table_bytes
    FROM index_usage JOIN index_counts USING ( relid )
    WHERE table_scans > 100
        AND table_scans > ( index_scans / 10 )
        AND table_bytes > 1000000000  
        AND writes_per_scan < ( 1.0 )
    ORDER BY table_bytes DESC
),
scans_no_writes AS (
    SELECT 'scans, no writes'::TEXT as reason,
        database, schema_name, table_name,
        table_scans, pg_size_pretty(table_bytes) as table_size,
        writes_per_scan, index_count, table_bytes
    FROM index_usage JOIN index_counts USING ( relid )
    WHERE table_scans > 100
        AND table_scans > ( index_scans / 4 )
        AND table_bytes > 32000000   
        AND writes_per_scan < ( 0.1 )
    ORDER BY writes_per_scan ASC
)
SELECT reason, database, schema_name, table_name, table_scans, 
    table_size, writes_per_scan, index_count
FROM too_many_tablescans
UNION ALL
SELECT reason, database, schema_name, table_name, table_scans, 
    table_size, writes_per_scan, index_count
FROM scans_no_index
UNION ALL
SELECT reason, database, schema_name, table_name, table_scans, 
    table_size, writes_per_scan, index_count
FROM big_tables_with_scans
UNION ALL
SELECT reason, database, schema_name, table_name, table_scans, 
    table_size, writes_per_scan, index_count
FROM scans_no_writes;




