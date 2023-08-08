#!/usr/bin/python3

import psycopg2
import sys
from optparse import OptionParser
from time import sleep
import os

parser = OptionParser()
parser.add_option("-d", "--database", dest="dbname",
                  help="database to scanned (required)", metavar="DBNAME")
parser.add_option("--debug", action="store_true", default=False, dest="debug",
                  help="print verbose debugging information", metavar="DEBUG")
parser.add_option("-m", "--minimum", dest="minimum",
                    help="minimum percent used", metavar="PERCENT",
                    default="0")
parser.add_option("-U", "--user", dest="dbuser",
                  help="database user", metavar="USERNAME",
                  default="")
parser.add_option("-H", "--host", dest="dbhost",
                  help="database host system", metavar="HOST",
                  default="")
parser.add_option("-p", "--port", dest="dbport",
                  help="database port", metavar="PORT",
                  default="")
parser.add_option("-w", "--password", dest="dbpass",
                  help="database password", metavar="PWD",
                  default="")

(options, args) = parser.parse_args()

def dq(val):
    return '"' + val + '"'

if options.debug:
    for var_name in ("PGHOST", "PGUSER", "PGPORT", "PGDATABASE", "PGPASSWORD"):
        value = os.getenv(var_name)
        print(f'{var_name}="{value}"')

connect_string = ""

if options.dbname:
    connect_string ="dbname=%s " % options.dbname

if options.dbhost:
    connect_string += " host=%s " % options.dbhost

if options.dbuser:
    connect_string += " user=%s " % options.dbuser

if options.dbpass:
    connect_string += " password=%s " % options.dbpass

if options.dbport:
    connect_string += " port=%s " % options.dbport

conn = psycopg2.connect(connect_string)
cur = conn.cursor()

# get a list of all integer fields with a key constraint on them
# or with an attached sequence

cur.execute("""SELECT table_schema, table_name, column_name, data_type,
        2::numeric ^ ( numeric_precision - 1 ) AS maxnum
    FROM information_schema.columns
        JOIN information_schema.key_column_usage USING ( table_schema, table_name, column_name )
    WHERE data_type IN ( 'bigint', 'integer' )
        AND key_column_usage.ordinal_position = 1
    UNION
    SELECT table_schema, table_name, column_name, data_type,
        2::numeric ^ ( numeric_precision - 1 ) AS maxnum
    FROM information_schema.columns
    WHERE column_default ILIKE '%nextval%'
    ORDER BY table_schema, table_name, column_name""")
collist = cur.fetchall()
if options.debug:
    print(f"Columns:\n\n{collist}")

exit_status = 0
rest = False
if len(collist) > 25:
    rest = True
# for each, fetch the current maximum value
for col in collist:
    (namespace, table, column, data_type, limit) = col

    if rest:
        sleep(.2)

    cur.execute(f'SELECT max("{column}") FROM "{namespace}"."{table}"')
    current = cur.fetchone()[0]

    if current and limit:
        pctused = current*100.0/float(limit)

        if pctused >= float(options.minimum):
            print(f"Column '{column}' of table '{namespace}.{table}' is {pctused:{3.1}} used")
            exit_status = 1

sys.exit(exit_status)
