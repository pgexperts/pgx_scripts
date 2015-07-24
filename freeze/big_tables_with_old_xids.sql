-- Top 20 tables over 1GB, sorted by the age of their oldest transaction ID
SELECT relname, age(relfrozenxid) as xid_age, 
    pg_size_pretty(pg_table_size(oid)) as table_size
FROM pg_class 
WHERE relkind = 'r' and pg_table_size(oid) > 1073741824
ORDER BY age(relfrozenxid) DESC LIMIT 20;
