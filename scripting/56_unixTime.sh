#!/bin/bash
#set -x
#
# unixTime.sh
#
# Print the current date, the current unix time(), and the current
# unix day (time()/86400), on a couple OSs.
#

case $(uname) in
  "Linux")
    echo
    printf "%-27s %10s" "Current Calendar Date (TZ):" "$(date +%F)"
    echo
    echo
    printf "%-27s %10d" "Current Epoch Time (UTC):" "$(date --utc +%s)"
    echo
    printf "%-27s %10d" "Current Epoch Date (UTC):" "$(( $(date --utc +%s)/86400 ))"
    echo
    ;;
  "SunOS")
    # Solaris 10. Solaris 11 might have a better way.
    i_unixtime=$( truss date 2>&1 | grep time | cut -d= -f2 | cut -c2-11 )
    echo
    printf "%-27s %10s" "Current Calendar Date (TZ):" "$(date +%Y-%m-%d)"
    echo
    echo
    printf "%-27s %10d" "Current Epoch Time (UTC):" "${i_unixtime}"
    echo
    printf "%-27s %10d" "Current Epoch Date (UTC):" "$(( ${i_unixtime}/86400 ))"
    echo
    ;;
esac


