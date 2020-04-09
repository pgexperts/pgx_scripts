with relage as (
select relname, age(relfrozenxid) as xid_age,
    round((relpages/128::numeric),1) as mb_size
    from pg_class
where relkind IN ('r', 't')
),
av_max_age as (
    select setting::numeric as max_age from pg_settings where name = 'autovacuum_freeze_max_age'
),
wrap_pct AS (
select relname, xid_age,
    round(xid_age*100::numeric/max_age, 1) as av_wrap_pct,
    round(xid_age*100::numeric/2200000000, 1) as shutdown_pct,
    mb_size
from relage cross join av_max_age
)
select wrap_pct.*, pgsa.pid
from wrap_pct
left outer join pg_stat_activity pgsa on (pgsa.query ilike '%autovacuum%' and pgsa.query ilike '%' || relname || '%')
where ((av_wrap_pct >= 75
    or shutdown_pct >= 50)
    and mb_size > 1000)
    or
    (av_wrap_pct > 100
    or shutdown_pct > 80)
order by xid_age desc;