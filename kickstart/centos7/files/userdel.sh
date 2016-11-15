#!/bin/bash
#set -x
#
# userdel.sh
#
# Delete unneeded users as part of the kickstart configuration.
#


###
### EXPLICIT VARIABLES
###

# If you add the user or group "nobody" to the list, use a different
# non-root user in the find commands at the end of this script for
# any orphaned files.

a_users=( \
ftp \
games \
halt \
mail \
operator \
shutdown \
sshd \
tcpdump \
tss \
)

a_groups=( \
dialout \
floppy \
games \
tape \
video \
ftp \
lock \
audio \
ssh_keys \
avahi-autoipd \
input \
tss \
dip \
slocate \
colord \
tcpdump \
stapusr \
stapsys \
stapdev \
)


###
### MAIN
###

# The loop to delete unneeded users
i_elements=${#a_users[*]}
i_index=0

while [ "${i_index}" -lt "${i_elements}" ]
do
  ${e_userdel} ${a_users[${i_index}]}

  ((i_index++))
done


# The loop to delete unneeded groups.
i_elements=${#a_groups[*]}
i_index=0

while [ "${i_index}" -lt "${i_elements}" ]
do
  ${e_groupdel} ${a_groups[${i_index}]}

  ((i_index++))
done

# Set any orphaned files to root user or root group.
# Inspired by STIG RHEL-07-020360 and RHEL-07-020370
find / -fstype local -xdev -nouser  -print -exec chown nobody {} \;
find / -fstype local -xdev -nogroup -print -exec chgrp nobody {} \;


