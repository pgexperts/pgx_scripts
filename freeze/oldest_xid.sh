#!/bin/sh

SCRIPT_NAME=`basename $0`

usage() {
    echo "Usage: $SCRIPT_NAME OUTPUT_FILE"
    exit 255
}

OUTPUT_FILE=$1
if [ "x$OUTPUT_FILE" = "x" ]; then
    usage
elif [ -e "$OUTPUT_FILE" ]; then
    echo "$SCRIPT_NAME: error: output file $OUTPUT_FILE already exists"
    exit 1
fi

VACUUM_FREEZE_MIN_AGE=`psql --no-align --tuples-only --command 'show vacuum_freeze_min_age'`
echo "txid_current at " `date +%F-%H%M-%Z` | tee --append $OUTPUT_FILE # race condition :(
psql --tuples-only --no-align --command 'SELECT txid_current()' | tee --append "$OUTPUT_FILE" 

"Current xid saved in $OUTPUT_FILE.
Now wait 4 hours (or 1 day, if you use long-running transactions)
and run this script again, with a different output file name.

Then subtract the first xid from the second and round up
to the nearest multiple of 10. This is your xid burn rate.
Use this number as the new value of vacuum_freeze_min_age[1]
in postgresql.conf, and do a server reload (NOT restart).

[1] (The current value is $VACUUM_FREEZE_MIN_AGE)"

