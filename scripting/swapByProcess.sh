#!/bin/bash 
# Get current swap usage for all running processes
# Erik Ljungstrom 27/05/2011
# Modified by Mikko Rantalainen 2012-08-09
# Pipe the output to "sort -nk3" to get sorted output
# Modified by Marc Methot 2014-09-18
# removed the need for sudo
# Modified by David Barr 2017-07-20
# Script found at
# https://stackoverflow.com/questions/479953/how-to-find-out-which-processes-are-swapping-in-linux
# Converted backtick child processes to $() child processes.
# Converted variable names to lower case with type prefixes.
# Converted echo statements to printf.
# As a result of printf statements, sort command is now "sort -nk4".


i_sum=0
i_overall=0

for d_test in $( find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+" )
do
  i_pid=$( echo ${d_test} | cut -d / -f 3 )
  s_progname=$( ps -p ${i_pid} -o comm --no-headers )

  for i_swap in $( grep VmSwap ${d_test}/status 2>/dev/null | awk '{ print $2 }' )
  do
    let i_sum=${i_sum}+${i_swap}
  done

  if (( ${i_sum} > 0 )); then
    printf "PID %6i swapped %8i KB (%s).\n" ${i_pid} ${i_sum} ${s_progname}
  fi

  let i_overall=${i_overall}+${i_sum}
  i_sum=0
done

printf "Overall swap used: %8i KB.\n" ${i_overall}
