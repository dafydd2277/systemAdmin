#!/bin/bash
#set -x
#
# removeOldKernels.sh
#
# This script scans hosts for multiple kernel and Oracle kernel-uek-*
# packages, and removes all the but the newest.
#
# 2016-02-10
# Created script
#
 
###
### DERIVCED VARIABLES
###
 
s_yes="-y"
if [ "$1" == "yes" ]
then
  s_yes="-y"
fi
 
###
### MAIN
###
 
 
# Kernel strings to search for via `rpm`.
a_kernel_strings=( kernel \
kernel-uek \
kernel-uek-firmware \
kernel-uek-headers \
kernel-uek-debug
)
 
# Loop through the ${a_kernel_strings} array.
s_packages=""
for s_kernel in "${a_kernel_strings[@]}"
do
  s_test=$(rpm -q ${s_kernel} | head -n -1 | tr '\n' ' ')
 
  if [ ! -z "${s_test}" ]
  then
    s_packages="${s_packages} ${s_test}"
  fi
 
  unset s_test
done
 
# Set the -x here to see the exact command run.
set -x
 
if [ ! -z "${s_packages}" ]
then
  yum -y remove ${s_packages}
fi
 
df -h /boot
 
