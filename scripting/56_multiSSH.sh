#! /bin/bash
#set -x
#
# multissh.sh <host file> "<command>"
#
# http://unix.stackexchange.com/questions/107800/using-while-loop-to-ssh-to-multiple-servers
#


f_input=${1}

s_command=${2}


while read -u10 s_host
do
  # Skip blank or commented lines.
  echo ${s_host} | egrep '^$\|^\s*\#' >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    continue
  fi

  # Execute the command.
  echo -e "###\n### ${s_host}\n###\n"
  (ssh -q ${s_host} "${s_command}")
  echo
done 10< ${f_input}

