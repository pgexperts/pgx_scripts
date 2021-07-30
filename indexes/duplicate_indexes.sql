
\o /tmp/duplicate-indexes.txt

-- check for exact matches
SELECT indrelid::regclass AS table
     , array_agg(indexrelid::regclass) AS duplicate_indexes
  FROM pg_index
 GROUP BY indrelid
     , indkey
HAVING COUNT(*) > 1
ORDER BY indrelid::regclass;

-- check for matches on only the first column of the index
-- requires some human eyeballing to verify
SELECT indrelid::regclass AS table
     , array_agg(indexrelid::regclass) AS duplicate_indexes_to_check
  FROM pg_index
 GROUP BY indrelid
     , indkey[0]
HAVING COUNT(*) > 1
ORDER BY indrelid::regclass;

\o
