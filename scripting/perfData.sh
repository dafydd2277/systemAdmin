#!/bin/bash
#
# perfData.sh
#
# Collect point-in-time performance data on a Linux system

###
### STATIC VARIABLES
###

d_dest=/tmp/performance


###
### DYNAMIC VARIABLES
###

s_date=$( date +%Y%m%d_%H%M )


###
### FUNCTIONS
###

get_top () {
  # Collect a `top` run
  top -bn1 >${d_dest}/top.${s_date}
}


get_swap_by_process () {
  # Collect swap information
  curl https://raw.githubusercontent.com/dafydd2277/systemAdmin/main/scripting/swapByProcess.sh \
    | /bin/bash \
    >${d_dest}/swapByProcess.${s_date}
}


get_cpu_and_memory () {
#  set -x
  # Collect Process Memory Information
  local df_out=${d_dest}/ps.${s_date}
  local r_cpu_total=0
  local r_mem_total=0
  
  ps -o pid,user,%cpu,%mem,command --forest ax >${df_out}
  
  while read line
  do
    if [ "PID" == $( echo ${line} | awk '{print $1}' ) ]
    then
      continue
    fi

    local r_cpu=$( echo ${line} | awk '{print $3}' )
    r_cpu_total=$( echo "${r_cpu_total}+${r_cpu}" | bc )

    local r_mem=$( echo ${line} | awk '{print $4}' )
    r_mem_total=$( echo "${r_mem_total}+${r_mem}" | bc )
  done <${df_out}
  
  echo -e "\nTotal CPU Usage: ${r_cpu_total}%" >>${df_out}
  echo "Total Memory Usage: ${r_mem_total}%" >>${df_out}
#  set +x
}


###
### MAIN
###

if [ ! -d ${d_dest} ]
then
  mkdir -p ${d_dest}
fi
chmod 1777 ${d_dest}

get_top
get_swap_by_process
get_cpu_and_memory


