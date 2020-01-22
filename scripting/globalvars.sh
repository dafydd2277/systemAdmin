# globalvars.sh
#
# This script is intended to be sourced by other installation scripts
# as a common code source. To source the file locally, execute
#
# source /path/to/globalvars.sh
#
# To source this file from a script server, execute
#
# source <( $(/usr/bin/which curl) -sS http://server/path/to/globalvars.sh )
#

###
### DERIVED VARIABLES
###

#set -x

# SET AN INSTALLATION STAGING DIRECTORY
d_install=${d_install:-/tmp/install}


# GATHER THE EXECUTABLES
s_old_path="${PATH}"
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/share/bin:/usr/share/sbin

e_awk=$( /usr/bin/which awk )
e_cat=$( /usr/bin/which cat )
e_chkconfig=$( /usr/bin/which chkconfig )
e_chmod=$( /usr/bin/which chmod )
e_chown=$( /usr/bin/which chown )
e_cp=$( /usr/bin/which cp )
e_curl=$( /usr/bin/which curl )
e_cut=$( /usr/bin/which cut )
e_date=$( /usr/bin/which date )
# Use the bash internal echo - e_echo=$( /usr/bin/which echo )
e_egrep=$( /usr/bin/which egrep )
e_find=$( /usr/bin/which find )
e_grep=$( /usr/bin/which grep )
e_groupadd=$( /usr/bin/which groupadd )
e_groupmod=$( /usr/bin/which groupmod )
e_hostname=$( /usr/bin/which hostname )
e_hostnamectl=$( /usr/bin/which hostnamectl )
e_id=$( /usr/bin/which id )
e_ln=$( /usr/bin/which ln )
e_ls=$( /usr/bin/which ls )
e_mkdir=$( /usr/bin/which mkdir )
e_mv=$( /usr/bin/which mv )
e_printf=$( /usr/bin/which printf )
e_rm=$( /usr/bin/which rm )
e_rpm=$( /usr/bin/which rpm )
e_sed=$( /usr/bin/which sed )
e_stat=$( /usr/bin/which stat  )
e_setsebool=$( /usr/bin/which setsebool )
e_sort=$( /usr/bin/which sort )
e_tar=$( /usr/bin/which tar )
e_touch=$( /usr/bin/which touch )
e_tput=$( /usr/bin/which tput )
e_tr=$( /usr/bin/which tr )
e_useradd=$( /usr/bin/which useradd )
e_usermod=$( /usr/bin/which usermod )
e_wc=$( /usr/bin/which wc )
e_wget=$( /usr/bin/which wget )
e_yum=$( /usr/bin/which yum )
e_unzip=$( /usr/bin/which unzip )
e_tput=$( /usr/bin/which tput )

e_iptables=$( /usr/bin/which iptables )
e_ip6tables=$( /usr/bin/which ip6tables )
if [ -z "${e_ip6tables}" ]
then
  e_ip6tables=${e_iptables}
fi

export PATH="${s_old_path}"

# ONLY CALL FOR THE HOSTNAME ONCE
s_fqdn=$( ${e_hostnamectl} \
          | ${e_grep} hostname \
          | ${e_awk} '{print $NF}' )
s_hostname=$( echo ${s_fqdn} | ${e_cut} -d. -f1 )
s_domain=${s_hostname#*.}
s_hostname_upper=$( echo ${s_hostname} | ${e_tr} [:lower:] [:upper:] )

# s_domain_prefix isolates the "sub" of "host.sub.dom.ain" for subdomain
# specific variables and usages
s_domain_prefix=$( echo ${s_fqdn} | ${e_cut} -d. -f2 )


# SET THE VERSION-DEPENDENT VARIABLES
source /etc/os-release
i_major_version=$( echo ${VERSION_ID} |  ${e_cut} -d. -f1 )
i_minor_version=$( echo ${VERSION_ID} |  ${e_cut} -d. -f2 )

# If /etc/os-release doesn't exist, then we're still on RHEL 5, and
# whole "source <(curl -sS http://...) stuff won't work anyway.
if [ -z "${i_major_version}" ]
then
 i_major_version=5
 i_minor_version=11
fi

case ${i_major_version} in
  '5')
    # VERSION-DEPENDENT VARIABLES
    e_service=$( /usr/bin/which service )
    ;;
  '6')
    # VERSION-DEPENDENT VARIABLES
    e_service=$( /usr/bin/which service )
    ;;
  '7')
    # VERSION-DEPENDENT VARIABLES
    e_systemctl=$( /usr/bin/which systemctl )

    # We still need a service command for things like
    # `service iptables save`.
    e_service=$( /usr/bin/which service )
    if [ -z "${e_service}" ]
    then
      e_service=${e_systemctl}
    fi
    ;;
esac


# SET THE DOMAIN-DEPENDENT VARIABLES
case ${s_domain_prefix} in
 'dev')
   # DOMAIN-DEPENDENT VARIABLES
   ;;
 'test')
   # DOMAIN-DEPENDENT VARIABLES
   ;;
 'prod')
   # DOMAIN-DEPENDENT VARIABLES
   ;;
 *)
   # DOMAIN-DEPENDENT VARIABLES
   ;;
esac


# SET A FILE EXTENSION VARIABLE FOR SED, ETC.
# ${e_sed} --in-place=.${s_daterev} "<sed program>" <file>
s_daterev=$( ${e_date} +%Y%m%d_%H%M%S )


###
### FUNCTIONS
###

# RING BELL / FLASH SCREEN
fn_global_bell () {
 echo -e "\a"
}


# STOP AND CONTINUE
fn_global_continue () {
 read -p "Are you ready to continue (y/n)? " s_response
 echo

 if [[ "${s_response}" =~ ^(y|Y|yes|Yes|YES)$ ]]
 then
   echo
 fi

 unset s_response
}


# COLOR SETTINGS FOR TPUT
#  Set ANSI Foreground color:         ${e_tput} setaf <number>
#  Reset to default foreground color: ${e_tput} sgr 0
#  Where <number> comes from value below:
#     Color       #define       Value       RGB
#     black     COLOR_BLACK       0     0, 0, 0
#     red       COLOR_RED         1     max,0,0
#     green     COLOR_GREEN       2     0,max,0
#     yellow    COLOR_YELLOW      3     max,max,0
#     blue      COLOR_BLUE        4     0,0,max
#     magenta   COLOR_MAGENTA     5     max,0,max
#     cyan      COLOR_CYAN        6     0,max,max
#     white     COLOR_WHITE       7     max,max,max
#
#  Example:
# echo "$(${e_tput} setaf 1)Changing to RED text$(${e_tput} sgr 0)"
#
# Or, set colors directly.
#
c_reset="\[\033[0m\]"
c_hicolor="\[\033[1m\]"
c_invert="\[\033[7m\]"
c_fg_black="\[\033[30m\]"
c_fg_red="\[\033[31m\]"
c_fg_green="\[\033[32m\]"
c_fg_yellow="\[\033[33m\]"
c_fg_blue="\[\033[34m\]"
c_fg_magenta="\[\033[35m\]"
c_fg_cyan="\[\033[36m\]"
c_fg_white="\[\033[37m\]"
c_bg_black="\[\033[40m\]"
c_bg_red="\[\033[41m\]"
c_bg_green="\[\033[42m\]"
c_bg_yellow="\[\033[43m\]"
c_bg_blue="\[\033[44m\]"
c_bg_magenta="\[\033[45m\]"
c_bg_cyan="\[\033[46m\]"
c_bg_white="\[\033[47m\]"


# PRINT GREEN TEXT
# Usage: fn_global_print_green "<quoted message text>"
fn_global_print_green () {
 echo -e "$( ${e_tput} setaf 2 )${1}$( ${e_tput} sgr 0 )"
}


# PRINT RED TEXT
# Usage: fn_global_print_red "<quoted message text>"
fn_global_print_red () {
 echo -e "$( ${e_tput} setaf 1 )${1}$( ${e_tput} sgr 0 )"
}


# CREATE OR CLEAR AN INSTALLATION STAGING DIRECTORY
fn_global_tmp_install () {
 if [ -d "${d_install}" ]
 then
   ${e_rm} -rf ${d_install}/*
   ${e_chmod} 1777 ${d_install}
 else
   ${e_mkdir} --mode=1777 --parents ${d_install}
 fi
}

#set +x

