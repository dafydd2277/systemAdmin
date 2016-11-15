#!/bin/bash
#set -x
#
# testSUID.sh
#
# This script runs the command specified in DISA STIG RHEL-07-030310.
# It will scan the host for files set SUID or SGID and craft
# audit.rules entries to audit execution of these files.


###
### EXPLICIT VARIABLES
###

a_filesystems=( \
/ \
/home \
/opt \
/tmp \
/usr \
/var \
/var/log \
/var/log/audit \
)


###
### MAIN
###

# Put a header line in the temp file.
${e_echo} "# STIG RHEL-07-030310" > /tmp/suidFiles.txt

# The loop to delete unneeded users
i_elements=${#a_filesystems[*]}
i_index=0

while [ "${i_index}" -lt "${i_elements}" ]
do
  ${e_echo} "Testing ${a_filesystems[${i_index}]}"

  a_files=( $( ${e_find} ${a_filesystems[${i_index}]} \
    -xdev \
    -type f \
    \( -perm -4000 -o -perm -2000 \) \
    2>/dev/null ) \
  )

  unset i_elements2 i_index2
  i_elements2=${#a_files[*]}
  i_index2=0

  while [ "${i_index2}" -lt "${i_elements2}" ]
  do
    ${e_echo} -n "-a always,exit -F ${a_files[${i_index2}]} " >> /tmp/suidFiles.txt
    ${e_echo} "-F perm=x -F auid>=1000 -F auid!=4294967295 -k setuid/setgid" >> /tmp/suidFiles.txt

    ((i_index2++))
  done

  unset a_files

  ((i_index++))
done


# Add a blink line.
${e_echo} "" >> /tmp/suidFiles.txt

# Add the SUID/SGID lines in before the final section.
${e_awk} '/# Disable/{while(getline line<"/tmp/suidFiles.txt"){print line}} //' /etc/audit/rules.d/audit.rules > /tmp/auditTemp
${e_mv} /tmp/auditTemp /etc/audit/rules.d/audit.rules
rm /tmp/suidFiles.txt

