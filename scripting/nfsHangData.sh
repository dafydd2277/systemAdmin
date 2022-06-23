#!/bin/bash
#set -x

###
### STATIC VARIABLES
###

# What's the boundary between a normal ping response and a slow one?
# This value is in milliseconds (ms).
slowPing=250


###
### DERIVED VARIABLES
###

# Get the PID of `nfsiod` and strip the leading tab char.
pid_nfsiod_raw=$( ps -C nfsiod -o pid= )
[[ ${pid_nfsiod_raw} =~ ([[:digit:]]{1,}) ]] && pid_nfsiod=${BASH_REMATCH[1]}


default_ifs=$IFS


###
### FUNCTIONS
###

fn_getPingTime() {
  local ipAddr=$1

  local timeLine=$( ping -c 1 ${ipAddr} | tail -1 )
  if [ $? -eq 0 ]
  then
    local time=$( echo ${timeLine} | cut -d= -f 2 | cut -d/ -f 2 )
    # Bash doesn't do floating point arithmetic.
    if (( $( bc -l<<<"${time}<${slowPing}" ) )) 
    then
      echo "Yes"
    else
      echo "No"
    fi
  else
    echo "PING FAILED"
  fi
}

fn_usage () {

echo "Usage: $0 [mountpoint] [mountpoint] ..."

cat <<EOT

This script will collect nfs mount information from either the selected
mount points or all NFS mountpoints handled by nfsiod. It will identify
the IP address the specific connection is using the contact the NFS
server. Then, it will perform and report on tests on that IP address to
validate connectivity.
EOT
}


###
### MAIN
###

# Get Help!
# "-?" can't be used as a "get help" request, because ? is a reserved
# character in bash.
while getopts h flag
do
  case "${flag}" in
    h) fn_usage
  esac
  exit 0
done

# Identify and format the requested mountpoints.
if [ ! -z ${1} ]
then
  s_egrep=${1}

  for d_mountpoint in "$@"
  do
  
    # We've already got the first one.
    if [ "${d_mountpoint}" == "${s_egrep}" ]
    then
      continue
    fi
  
    # Assemble the alternatives string.
    s_egrep="${s_egrep}|${d_mountpoint}"
    
  done
  #echo "s_egrep: ${s_egrep}"

  IFS=$'\n'
  s_lines=$( egrep "(${s_egrep})" /proc/${pid_nfsiod}/mounts | grep ' nfs ' )
else
  IFS=$'\n'
  s_lines=$( grep ' nfs ' /proc/${pid_nfsiod}/mounts )
fi

# Process the results of the search for nfs/autofs mounts of
# interest.
for s_line in $s_lines
do
  IFS=$default_ifs

  # Split out the mount information we care about.
  read -r -a a_mountEntry <<< "$s_line"
  s_mountSource=${a_mountEntry[0]}
  s_mountPoint=${a_mountEntry[1]}
  s_mountOptions=${a_mountEntry[3]}

  format="%-11s %s\n"
  printf "${format}" "Source:" ${s_mountSource}
  printf "${format}" "Mounted on:" ${s_mountPoint}

  # Split up the mountOptions.
  IFS=','
  read -r -a a_mountOpts <<< "$s_mountOptions"
  IFS=$default_ifs

  # Get the IP address used for the connection.
  for s_option in ${a_mountOpts[@]}
  do
    [[ ${s_option} =~ "mountaddr" ]] && s_sourceAddr=$( echo ${s_option} \
      | cut -d= -f 2 )
  done

  # Perform tests on that IP address.
  pingTime=$( fn_getPingTime ${s_sourceAddr} )
  s_nmapOut=$( nmap --open -p111 ${s_sourceAddr} \
    | egrep '^111' \
    | tr -s ' ' | cut -d ' ' -f 2 )


  # Print the output
  format="%-21b\t%-20b\n"
  printf $format "Connected IP Address" ${s_sourceAddr}
  printf $format "Ping less than ${slowPing}ms" ${pingTime}
  printf $format "Nmap scan of port 111" ${s_nmapOut}

  echo
done


IFS=$default_ifs

