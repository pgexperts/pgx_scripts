
\o /tmp/duplicate-indexes.txt

SELECT * FROM (
SELECT DISTINCT ON (rel, idx) * FROM (

-- check for full matches
SELECT indrelid::regclass AS rel
     , array_agg(indexrelid::regclass) AS idx,
		'0 - COLUMN & CLASS EXACT' AS match_type
  FROM pg_index
 GROUP BY indrelid
     , indkey
		, indclass
HAVING COUNT(*) > 1

UNION

-- check for column matches ignoring class
SELECT indrelid::regclass AS rel
     , array_agg(indexrelid::regclass) AS idx,
		'1 - COLUMN EXACT' AS match_type
  FROM pg_index
 GROUP BY indrelid
     , indkey
HAVING COUNT(*) > 1

UNION

-- check for first column matches
-- requires human eyeball verification
SELECT indrelid::regclass AS rel
     , array_agg(indexrelid::regclass) AS idx,
		'2 - PARTIAL' AS match_type
  FROM pg_index
 GROUP BY indrelid
     , indkey[0]
HAVING COUNT(*) > 1

ORDER BY match_type) tmp
ORDER BY rel, idx, match_type) tmp2 ORDER BY match_type;

\o
