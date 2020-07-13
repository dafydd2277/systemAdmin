#!/bin/bash
#set -x
#
# getInstalledKernels.sh
#
# This script will identify and compare the current running kernel
# with the latest installed kernel, and highlight differences.
#
# See the git commit log ( `git log itil/getInstalledKernels.sh` ) for
# the update history.
#


###
### EXPLICIT VARIABLES
###

d_outfile=/var/tmp/reports
f_outfile=getInstalledKernels


###
### DERIVED VARIABLES
###

source ./libitil.sh
fn_libitil_get_latest_kernels

# Assemble the full $df_outfile.
df_outfile="${d_outfile}/${f_outfile}.$( date +%F ).csv"
df_tmpfile="${d_outfile}/$$"


###
### FUNCTIONS
###

fn_interrupt () {
  rm -f ${df_outfile}
  rm -f ${df_tmpfile}
}


###
### MAIN
###

# Save the requested host.
s_host=${1:-}

# Manage the output directory.
fn_libitil_clean_output ${d_outfile} ${f_outfile}

# Set the IFS for whole lines only. Save the normal setting to
# replace afterward.
oldIFS=${IFS}
export IFS=$'\n'

# Build the SELECT statement for the requested host, or all hosts.
if [ -z "${s_host}" ]
then
  s_sql_search="SELECT hostname,domainname,kernelrelease,uptime_hours,datetime(last_updated, \"localtime\") "
  s_sql_search=${s_sql_search}"FROM hosts;"
else
  s_hostname=$( fn_libitil_get_hostname ${s_host} )
  s_domainname=$( fn_libitil_get_domainname ${s_host} )

  # If the requested host string is an FQDN, use that. Otherwise, use
  # the simple hostname.
  if [ -z "${s_domainname}" ]
  then
    s_sql_search="SELECT hostname,domainname,kernelrelease,uptime_hours) "
    s_sql_search=${s_sql_search}"FROM hosts "
    s_sql_search=${s_sql_search}"WHERE hostname=\"${s_hostname}\";"
  else
    s_sql_search="SELECT hostname,domainname,kernelrelease,uptime_hours) "
    s_sql_search=${s_sql_search}"FROM hosts "
    s_sql_search=${s_sql_search}"WHERE hostname=\"${s_hostname}\" "
    s_sql_search=${s_sql_search}"AND domainname=\"${s_domainname}\";"
  fi
fi


# Execute that SELECT statement, and loop through the results.

for s_line in $( ${e_sqlite3} ${df_itildb} "${s_sql_search}" )
do
  # Parse the SELECT output.
  s_hostname=$( echo ${s_line} | cut -d'|' -f 1 )
  s_domainname=$( echo ${s_line} | cut -d'|' -f 2 )
  s_fqdn="${s_hostname}.${s_domainname}"
  s_kernelrelease=$( echo ${s_line} | cut -d'|' -f 3 )
  fn_libitil_convert_uptime $( echo ${s_line} | cut -d'|' -f 4 )


  # Get the currently installed kernel
  s_rpm_out=$( ssh -o "ConnectTimeout 2" -q ${s_fqdn} "rpm --last -q kernel | head -1" )

  s_installed_kernel_version=$( echo ${s_rpm_out} | awk '{print $1}' | cut -d'-' -f 2- )
  if [ -z "${s_installed_kernel_version}" ]
  then
    s_installed_kernel_version="UNAVAILABLE"
  fi

  s_installed_kernel_date=$( echo ${s_rpm_out} | tr -s [:blank:] | cut -d' ' -f 2- )
  if [ -z "${s_installed_kernel_date}" ]
  then
    s_installed_kernel_date="UNAVAILABLE"
  else
    s_installed_kernel_date=$( date --date="${s_installed_kernel_date}" --rfc-3339=seconds )
  fi


  # Is the most recent installed kernel the latest available kernel?
  # If yes, is it actually the current running kernel?
  if $( echo ${s_kernelrelease} | egrep -q '^2' )
  then
    s_latest_kernel=${s_latest_kernel2}
  elif $( echo ${s_kernelrelease} | egrep -q '^3' )
  then
    s_latest_kernel=${s_latest_kernel3}
  fi

  if [ "${s_installed_kernel_version}" != "${s_latest_kernel}" ]
  then
    s_message="UPDATE - Kernel ${s_latest_kernel} is not installed"
  elif [ "${s_kernelrelease}" != "${s_installed_kernel_version}" ]
  then
    s_message="REBOOT - A more recent kernel is installed on this host."
  else
    s_message=""
  fi

  echo "${s_hostname},${s_domainname},${s_kernelrelease},${s_installed_kernel_version},${s_installed_kernel_date},${s_message}" \
    | tee -a ${df_tmpfile}

done


echo "HOSTNAME,DOMAINNAME,CURRENT RUNNING KERNEL,LATEST INSTALLED KERNEL,LATEST INSTALLED DATE,MESSAGE" \
  > ${df_outfile}
sort ${df_tmpfile} >> ${df_outfile}
rm -f ${df_tmpfile}

# Restore the normal IFS variable.
export IFS=${oldIFS}

