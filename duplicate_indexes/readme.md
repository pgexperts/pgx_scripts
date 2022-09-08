# Check for Duplicate Indexes

This is a script that checks for duplicate indexes in a more user-friendly fashion than our previous ones.  Just run it in the database you want to check.

This check returns results as a "duplicate index" and an "encompassing index." The theory is that you can drop the duplicate index in favor of the encompassing index.

Do not just follow this blindly, though!  For example, if you have two identical indexes, they'll appear in the report as a pair twice: once with one as the duplicate and the other as encompassing, and then the reverse. (If there are three, the report shows all possible pairs.) Be sure you leave one!

Always review before dropping, and test in development or staging before dropping from your production environment.

Some notes:

* We recommend enabling extended output in psql with \\x for better readability.

* This check skips:

  * `pg_*` tables
  * Any index that contains an expression, since those are hard to check for duplicates. Those should be checked manually.

* A primary key index will never be marked as a "duplicate."

* Check for indexes on Foreign Keys and referenced columns. For referenced columns, dropping the duplicate index is not usually a problem, but for Foreign Keys you may have a tradeoff between query performance _vs_ INSERT, UPDATE, DELETE performance.

* Your statistics may show that the "duplicate" index is being used;  this is normal and not an argument to keep the duplicate.  Postgres should switch to using the encompassing index once the duplicate is gone.

## Example output

-[ RECORD 1 ]-----------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
table                         | public.foo
dup index                     | index_foo_on_bar
dup index definition          | CREATE INDEX index_foo_on_bar ON public.foo USING btree (bar)
dup index attributes          | 2
encompassing index            | index_foo_on_bar_and_baz
encompassing index definition | CREATE INDEX index_foo_on_bar_and_baz ON public.foo USING btree (bar, baz)
enc index attributes          | 2 3

Since the multi-column index `index_foo_on_bar_and_baz` would be used for searches on the `bar` column, we can drop the individual index `index_foo_on_bar`.

