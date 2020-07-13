#!/bin/bash
#
# kernelReleaseByDomain.sh
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

s_printf_format="%27s is running %6s %4s, with kernel %25s.\n"

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

lines=$( ${e_sqlite3} ${s_dbname} \
  "SELECT hostname,domainname,os_name,os_release_full,kernelrelease FROM hosts" \
  | sort -t'|' -k2,1 )

for s_line in ${lines}
do

  s_fqdn=$( echo ${s_line} | cut -d'|' -f1 )"."$( echo ${s_line} | cut -d'|' -f2 )
  s_os_name=$( echo ${s_line} | cut -d'|' -f3 )
  s_release_full=$( echo ${s_line} | cut -d'|' -f4 )
  s_kernel=$( echo ${s_line} | cut -d'|' -f5 )

  printf ${s_printf_format} ${s_fqdn} ${s_os_name} \
    ${s_release_full} ${s_kernel} 

done

export IFS=${oldIFS}

