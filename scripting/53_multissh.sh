#! /bin/bash
#set -x
#
# multissh.sh <hosts file> "<command list>"
#
# Iterate through the hosts in <hosts file> and apply <command list> to the
# each host consecutively.
#
# ssh takes standard input, and so will swallow the contents of the host
# file. Here's one fix.
# http://unix.stackexchange.com/questions/107800/using-while-loop-to-ssh-to-multiple-servers
# Another would be `ssh -q "${s_host}" "${s_command}" </dev/null`
#
# How to skip blank lines and comments in the hosts file?
# http://stackoverflow.com/questions/17392869/how-to-print-a-file-excluding-comments-and-blank-lines-using-grep-sed
#
# AUTHOR David Barr <dafydd@dafydd.com>
#
# CHANGELOG
#
# 2016-03-10
# Create the script.
#
 

###
### DERIVED VARIABLES
###
 
f_input=${1}
s_command=${2}

 
###
### MAIN
###

while read -r -u10 s_host
do
  # Skip commented entries and blank lines.
  echo "${s_host}" | egrep '^$|^\s*#' >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    continue
  fi

  # Execute the command.
  echo -e "###\n### ${s_host}\n###\n"
  ssh -q "${s_host}" "${s_command}"
  echo
done 10< "${f_input}"

