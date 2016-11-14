#! /bin/bash
set -x

# Copy master file copies into a new installation.
#

###
### EXPLICIT VARIABLES
###


# Specify executable paths
export e_basename=$( /usr/bin/which basename )
export e_cut=$( /usr/bin/which cut )
export e_echo=$( /usr/bin/which echo )
export e_hostname=$( /usr/bin/which hostname )
export e_systemctl=$( /usr/bin/which systemctl )


###
### MAIN
###

# Set the array of golden files, using single quoted, space separated,
# strings of the form
# '/<path>/<file> <user>:<group> <numeric perms>'

a_goldenfiles=( \
  '/etc/audit/auditd.conf root:root 0640' \
  '/etc/audit/audit.rules root:root 0640' \
  '/etc/cron.daily/aide root:root 0640' \
  '/etc/default/useradd root:root 0644' \
  '/etc/issue root:root 0644' \
  '/etc/login.defs root:root 0644' \
  '/etc/modprobe.d/disa_stig.conf root:root 0640' \
  '/etc/pam.d/password-auth-ac root:root 0644' \
  '/etc/pam.d/system-auth-ac root:root 0644' \
  '/etc/security/pwquality.conf root:root 0644' \
  '/etc/ssh/sshd_config root:root 0600' \
  '/etc/yum.conf root:root 0644' \
)


i_elements=${#a_goldenfiles[*]}
i_index=0

# The loop to copy the golden files into place.
while [ "${i_index}" -lt "${i_elements}" ]
do
  df_target=$( ${e_echo} ${a_goldenfiles[${i_index}]} | cut -d' ' -f1 )
  f_target=$( ${e_basename} ${df_target} )
  s_owner=$( ${e_echo} ${a_goldenfiles[${i_index}]} | cut -d' ' -f2 )
  s_perms=$( ${e_echo} ${a_goldenfiles[${i_index}]} | cut -d' ' -f3 )

  mv ${df_target} ${df_target}.orig
  wget -O ${df_target} http://${h_file_source}/${s_file_path}/${f_target}

  chown ${s_owner} ${df_target}
  chmod ${s_perms} ${df_target}
  
  unset df_target f_target s_owner s_perms

  ((i_index++))
done

