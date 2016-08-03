
\o /tmp/duplicate-indexes.txt

-- check for exact matches
SELECT indrelid::regclass
     , array_agg(indexrelid::regclass)
  FROM pg_index
 GROUP BY indrelid
     , indkey
HAVING COUNT(*) > 1;

-- check for matches on only the first column of the index
-- requires some human eyeballing to verify
SELECT indrelid::regclass
     , array_agg(indexrelid::regclass)
  FROM pg_index
 GROUP BY indrelid
     , indkey[0]
HAVING COUNT(*) > 1;

\o
