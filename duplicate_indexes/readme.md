# Check for Duplicate Indexes

Unneeded indexes, such as duplicates, take up disk space, require time to vacuum, and slow down update and insert operations

This script checks for duplicate indexes in a more user-friendly fashion than our previous ones.  Just run it in the database you want to check.

Results are reported as a "duplicate index" and an "encompassing index." The theory is that you can drop the duplicate index in favor of the encompassing index.

Do not just follow this blindly, though!  For example, if you have two identical indexes, they'll appear in the report as a pair twice: once with one as the duplicate and the other as encompassing, and then the reverse. (If there are three, the report shows all possible pairs.) Be sure you leave one!

Always review before dropping, and test in development or staging before dropping from your production environment.

Some notes:

* We recommend enabling extended output in psql with \\x for better readability.

* This check skips:

  * `pg_*` tables
  * Any index that contains an expression, since those are hard to check for duplicates. Those should be checked manually.

* A primary key index will never be marked as a "duplicate."

* Review results for indexes on Foreign Keys and referenced columns. For referenced columns, dropping the duplicate index is not usually a problem, but for Foreign Keys you may have a tradeoff between query performance _vs_ INSERT, UPDATE, DELETE performance.

* Your statistics may show that the "duplicate" index is being used;  this is normal and not an argument to keep the duplicate.  Postgres should switch to using the encompassing index once the duplicate is gone.

* A lot of folks react to this report with "How could this happen!?!"  This is not a personal failing; if you're using an ORM for schema management, that's probably the source of most if not all of the duplicates.  You may have to do some manual wrangling with your ORM to prevent them from re-occurring.

## Example output

```
-[ RECORD 1 ]-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
table                         | public.foo
dup index                     | index_foo_on_bar
dup index definition          | CREATE INDEX index_foo_on_bar ON public.foo USING btree (bar)
dup index attributes          | 2
encompassing index            | index_foo_on_bar_and_baz
encompassing index definition | CREATE INDEX index_foo_on_bar_and_baz ON public.foo USING btree (bar, baz)
enc index attributes          | 2 3
```

Since the multi-column index `index_foo_on_bar_and_baz` would be used for searches only on the `bar` column, we can drop the individual index `index_foo_on_bar`.

```
-[ RECORD 2 ]-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
table                         | public.movies
dup index                     | index_movies_on_title
dup index definition          | CREATE INDEX index_movies_on_title ON public.movies USING btree (title)
dup index attributes          | 2
encompassing index            | index_movies_on_title_and_studio
encompassing index definition | CREATE UNIQUE INDEX index_movies_on_title_and_studio ON public.movies USING btree (title, studio)
enc index attributes          | 2 3
```

Same as example #1: the multi-column index `index_movies_on_title_and_studio` would be used for searches on just the `title` column, we can drop the individual index `index_movies_on_title`.

This next example shows what happens with multiple duplicate indexes:

```
demo_db=# \d+ index_demo
                                                Table "public.index_demo"
 Column |  Type   | Collation | Nullable |                Default                 | Storage  | Stats target | Description
--------+---------+-----------+----------+----------------------------------------+----------+--------------+-------------
 id     | integer |           | not null | nextval('index_demo_id_seq'::regclass) | plain    |              |
 name   | text    |           |          |                                        | extended |              |
Indexes:
    "idx_demo_name_uniq" UNIQUE, btree (name)
    "unique_name" UNIQUE CONSTRAINT, btree (name)
    "idx_demo_name" btree (name)
```

```
:::-->cat duplicate_indexes.txt
-[ RECORD 1 ]-----------------+-------------------------------------------------------------------------------
table                         | public.index_demo
dup index                     | idx_demo_name
dup index definition          | CREATE INDEX idx_demo_name ON public.index_demo USING btree (name)
dup index attributes          | 2
encompassing index            | idx_demo_name_uniq
encompassing index definition | CREATE UNIQUE INDEX idx_demo_name_uniq ON public.index_demo USING btree (name)
enc index attributes          | 2
-[ RECORD 2 ]-----------------+-------------------------------------------------------------------------------
table                         | public.index_demo
dup index                     | idx_demo_name
dup index definition          | CREATE INDEX idx_demo_name ON public.index_demo USING btree (name)
dup index attributes          | 2
encompassing index            | unique_name
encompassing index definition | CREATE UNIQUE INDEX unique_name ON public.index_demo USING btree (name)
enc index attributes          | 2
-[ RECORD 3 ]-----------------+-------------------------------------------------------------------------------
table                         | public.index_demo
dup index                     | idx_demo_name_uniq
dup index definition          | CREATE UNIQUE INDEX idx_demo_name_uniq ON public.index_demo USING btree (name)
dup index attributes          | 2
encompassing index            | unique_name
encompassing index definition | CREATE UNIQUE INDEX unique_name ON public.index_demo USING btree (name)
enc index attributes          | 2
-[ RECORD 4 ]-----------------+-------------------------------------------------------------------------------
table                         | public.index_demo
dup index                     | unique_name
dup index definition          | CREATE UNIQUE INDEX unique_name ON public.index_demo USING btree (name)
dup index attributes          | 2
encompassing index            | idx_demo_name_uniq
encompassing index definition | CREATE UNIQUE INDEX idx_demo_name_uniq ON public.index_demo USING btree (name)
enc index attributes          | 2
```

Note that the UNIQUE CONSTRAINT shows up as its underlying index.  You only need to keep one of these three indexes;  usually that's one of the UNIQUE options.
