#!/bin/bash
#
# uptimebyTime.sh
#
# This script will SELECT hostnames, domainnames, uptime, and 
# last_updated values for each host in the ${s_dbname} database, and
# return that information to the script invoker in a readble format.
#
# 2020-02-12 David Barr
# Initial Script
#


###
### EXPLICIT VARIABLES
###

# If not already set as an environment variable, set the ITIL database
# name.
s_dbname=${s_dbname:-/usr/local/lib/itil/itil.sqlite}


###
### DERIVED VARIABLES
###

# Parameterize the sqlite3 executable, with its full path.
e_sqlite3=$( /usr/bin/which sqlite3 )


###
### MAIN
###

oldIFS=${IFS}
export IFS=$'\n'

${e_sqlite3} ${s_dbname} \
  "SELECT hostname,domainname,datetime(last_updated, 'localtime') FROM hosts" \
  | sort -t'|' -k1 

export IFS=${oldIFS}

