with datage as (
select datname, age(datfrozenxid) as xid_age,
    round(pg_database_size(oid)/(128*1024::numeric),1) as gb_size
    from pg_database 
    where datname not in ('rdsadmin') -- no perms to examine this one (AWS)
),
av_max_age as (
    select setting::numeric as max_age from pg_settings where name = 'autovacuum_freeze_max_age'
),
wrap_pct AS (
select datname, xid_age,
    round(xid_age*100::numeric/max_age, 1) as av_wrap_pct,
    round(xid_age*100::numeric/2200000000, 1) as shutdown_pct,
    gb_size
from datage cross join av_max_age
)
SELECT wrap_pct.*
FROM wrap_pct
WHERE ((av_wrap_pct >= 75 or shutdown_pct > 50
    and gb_size > 1))
    or (av_wrap_pct > 100 or shutdown_pct > 80)
order by xid_age desc;
