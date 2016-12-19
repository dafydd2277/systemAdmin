#! /bin/bash
set -x

# Copy master file copies into a new installation.
#

###
### EXPLICIT VARIABLES
###

# Set the array of golden files, using single quoted, space separated,
# strings of the form
# '/<path>/<file> <user>:<group> <numeric perms>'

a_goldenfiles=( \
  '/etc/audit/auditd.conf root:root 0640' \
  '/etc/audit/rules.d/audit.rules root:root 0640' \
  '/etc/cron.daily/aide root:root 0640' \
  '/etc/default/useradd root:root 0644' \
  '/etc/issue root:root 0644' \
  '/etc/login.defs root:root 0644' \
  '/etc/modprobe.d/disa_stig.conf root:root 0640' \
  '/etc/pam.d/password-auth-ac root:root 0644' \
  '/etc/pam.d/system-auth-ac root:root 0644' \
  '/etc/postfix/main.cf root:root 0644' \
  '/etc/profile.d/stig.sh root:root 0644' \
  '/etc/rsyslog.conf root:root 0644' \
  '/etc/security/limits.conf root:root 0644' \
  '/etc/security/pwquality.conf root:root 0644' \
  '/etc/ssh/sshd_config root:root 0600' \
  '/etc/yum.conf root:root 0644' \
)

# Specify executable paths
e_basename=$( /usr/bin/which basename )
e_chmod=$( /usr/bin/which chmod )
e_chown=$( /usr/bin/which chown )
e_cut=$( /usr/bin/which cut )
e_echo=$( /usr/bin/which echo )
e_hostname=$( /usr/bin/which hostname )
e_mv=$( /usr/bin/which mv )
e_systemctl=$( /usr/bin/which systemctl )
e_wget=$( /usr/bin/which wget )


###
### MAIN
###

i_elements=${#a_goldenfiles[*]}
i_index=0

# The loop to copy the golden files into place.
while [ "${i_index}" -lt "${i_elements}" ]
do
  a_target=$( ${e_echo} ${a_goldenfiles[${i_index}]} )
  df_target=${a_target[0]}
  f_target=$( ${e_basename} ${df_target} )
  s_owner=${a_target[1]}
  s_perms=${a_target[2]}

  if [ -e "${df_target}" ]
  then
    ${e_mv} ${df_target} ${df_target}.orig
  fi

  ${e_wget} -O ${df_target} http://${h_file_source}/${s_file_path}/${f_target}

  ${e_chown} ${s_owner} ${df_target}
  ${e_chmod} ${s_perms} ${df_target}
  
  unset a_target df_target f_target s_owner s_perms

  ((i_index++))
done

