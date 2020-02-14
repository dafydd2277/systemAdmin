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

s_printf_format="%15s has been up %3d days, %2d hours, as of %s.\n"

###
### DERIVED VARIABLES
###

# Parameterize the sqlite3 executable, with its full path.
e_sqlite3=$( /usr/bin/which sqlite3 )


###
### FUNCTIONS
###

# Convert the uptime-in-hours to days and hours < 24.
#
# Usage: `fn_convert_uptime <Hours>`
fn_convert_uptime () {
  local i_uptime=${1:-}

  if [ -z "${i_uptime}" ]
  then
    return
  fi

  i_uptime_div24=$( expr ${i_uptime} / 24 )
  i_uptime_mod24=$( expr ${i_uptime} % 24 )

}


###
### MAIN
###

oldIFS=${IFS}
export IFS=$'\n'

lines=$( ${e_sqlite3} ${s_dbname} \
  "SELECT hostname, \
    domainname, \
    uptime_hours, \
    datetime(last_updated, 'localtime') \
    FROM hosts" \
  | sort -t'|' -k3 -rn )

for s_line in ${lines}
do

  i_uptime_hours=$( echo ${s_line} | cut -d'|' -f3 )
  fn_convert_uptime ${i_uptime_hours}

  s_fqdn=$( echo ${s_line} | cut -d'|' -f1 )"."$( echo ${s_line} | cut -d'|' -f2 )
  s_last_updated=$( echo ${s_line} | cut -d'|' -f4 )

  printf ${s_printf_format} ${s_fqdn} ${i_uptime_div24} \
    ${i_uptime_mod24} ${s_last_updated}

done

export IFS=${oldIFS}
