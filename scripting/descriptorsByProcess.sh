#!/bin/bash 
#
# Get current file descriptors for all running processes
#
# Inspired by 
# https://stackoverflow.com/questions/479953/how-to-find-out-which-processes-are-swapping-in-linux
# and
# https://github.com/dafydd2277/systemAdmin/blob/main/scripting/swapByProcess.sh


i_overall=0

for d_test in $( find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+" )
do
  i_pid=$( echo ${d_test} | cut -d / -f 3 )
  s_progname=$( ps -p ${i_pid} -o comm --no-headers )

  i_fds=$( ls -1 ${d_test}/fd 2>/dev/null | wc -l )
  let i_overall=${i_overall}+${i_fds}

  if [ ${i_fds} -gt 0 ]
  then
    printf "PID %6i has %4i fds open (%s).\n" ${i_pid} ${i_fds} ${s_progname}
  fi
done

printf "Overall file descriptors used: %4i.\n" ${i_overall}

