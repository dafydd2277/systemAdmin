#!/bin/bash
#set -x
#
# removeOldKernels.sh
#
# This script scans hosts for multiple kernel and Oracle kernel-uek-*
# packages, and removes all the but the newest. It was designed to be
# run as
#
# curl http://${server}/removeOldKernels.sh | /bin/bash
#
# 2016-02-10
# Created script
#
 
###
### USAGE REQUIREMENTS
###

if [ $(id -u) -ne 0 ]
then
  echo "Must be run as root."
  exit 1
fi


###
### EXPLICIT VARIABLES
###

# Kernel strings to search for via `rpm`.
a_kernel_strings=( \
kernel \
kernel-core \
kernel-firmware \
kernel-debug \
kernel-devel \
kernel-headers \
kernel-modules \
kernel-tools \
kernel-tools-libs \
kernel-uek \
kernel-uek-firmware \
kernel-uek-headers \
kernel-uek-debug \
kernel-uek-devel \
)
 

###
### MAIN
###
 
 
# Loop through the ${a_kernel_strings} array, and select all but the
# last
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
 
# Remove the discovered set of packages.
if [ ! -z "${s_packages}" ]
then
  yum -y remove ${s_packages}
fi
 
# How stuffed is /boot, now?
df -h /boot
 
