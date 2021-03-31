#!/bin/bash
set -x
#
# configGRUB.sh
#
# This script configures the GRUB_CMDLINE_LINUX variable in
# /etc/default/grub for FIPS use.
#
# The RHEL 7 family doesn't assign /dev/sda, etc., in predictable
# ways. So, just setting "fips=1 boot=/dev/sda1" in the kickstart
# bootloader entry may not work on systems with more than one disk.
# The UUID of the boot partition needs to be identified and used
# instead.
#
# REFERENCE: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/chap-Federal_Standards_and_Regulations.html
#
# HISTORY:
# 2017-04-11 David Barr
# Created the script.
#

###
### EXPLICIT VARIABLES
###

df_default_grub=/etc/default/grub
df_grub_cfg=/boot/grub2/grub.cfg

###
### DERIVED VARIABLES
###

s_old_path="${PATH}"
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

e_awk=$( /usr/bin/which awk )
e_blkid=$( /usr/bin/which blkid )
e_cut=$( /usr/bin/which cut )
e_df=$( /usr/bin/which df )
e_grep=$( /usr/bin/which grep )
e_grub2_mkconfig=$( /usr/bin/which grub2-mkconfig )
e_sed=$( /usr/bin/which sed )
e_tail=$( /usr/bin/which tail )

export PATH=${s_old_path}


###
### FUNCTIONS
###

# GET THE BOOT DISK UUID
fn_grub_get_uuid () {

  s_boot_partition=$( ${e_df} -h /boot \
    | ${e_tail} -1 \
    | ${e_awk} '{ print $1 }' )
  
  s_boot_uuid=$( ${e_blkid} \
                  -o export \
                  ${s_boot_partition} \
                  | ${e_grep} LABEL \
                  | ${e_cut} -d= -f2 )
}



# SET THE GRUB DEFAULT FILE TO INCLUDE SINGLE USER MODE OPTIONS
fn_grub_enable_single () {

  ${e_sed} --in-place \
    "s%^GRUB_DEFAULT=.*%GRUB_DEFAULT=0%" \
    ${df_default_grub}

  ${e_sed} --in-place \
    "s%^GRUB_DISABLE_SUBMENU=.*%GRUB_DISABLE_SUBMENU=true%" \
    ${df_default_grub}

  ${e_sed} --in-place \
    "s%^GRUB_DISABLE_RECOVERY=.*%GRUB_DISABLE_RECOVERY=false%" \
    ${df_default_grub}
}


###
### MAIN
###

# GET CURRENT VALUES
source ${df_default_grub}

# GET THE UUID
fn_grub_get_uuid

# MODIFY THE COMMAND LINE ENTRY
s_grub_cmdline="${GRUB_CMDLINE_LINUX}  boot=UUID=${s_boot_uuid}"

# SET THE NEW COMMAND LINE
${e_sed} --in-place=.orig \
  "s%^GRUB_CMDLINE_LINUX.*$%GRUB_CMDLINE_LINUX=\"${s_grub_cmdline}\"%" \
  ${df_default_grub}

# ENABLE SINGLE USER OPTIONS IN THE GRUB BOOT MENU
fn_grub_enable_single


${e_grub2_mkconfig} -o ${df_grub_cfg}
