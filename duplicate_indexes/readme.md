# Check for Duplicate Indexes

This is a script that checks for duplicate indexes in a more user-friendly fashion than our previous ones.  Just run it in the database you want to check.

Some notes:

* Turn on extended output in psql with \\x for best results.

* It deliberately does not check any index that contains an expression, since those are hard to check for duplicates. Those should be checked manually.

* It returns the results as a "duplicate index" and an "encompassing index." The theory is that you can drop the duplicate index in favor of the encompassing index. Note that if two indexes are identical, they'll come back as a pair twice: once with one as the duplicate and the other as encompassing, and then the reverse. (If there are three, it'll show all possible pairs.) Be sure you leave one!