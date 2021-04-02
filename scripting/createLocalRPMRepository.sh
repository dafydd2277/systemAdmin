#!/bin/bash
(
set -x
#
# createLocalRPMRepository.sh
#
#
# This script will move the current contents of /etc/yum.repos.d/ out
# of the way, place a repo file with the Oracle Linux public
# repositories, and then duplicate those repositories to the local
# host.
#

###
### USAGE VALIDATIONS
###

if [ "$(id -u)" -ne 0 ]
then
 $( /bin/which echo ) "Usage: $0"
 $( /bin/which echo ) "Must be run as root."
 exit 1
fi


###
### EXPLICIT VARIABLES
###

d_repo_base=/srv/www/yum
d_rpm_gpg=${d_repo_base}/keys

e_createrepo=$( /usr/bin/which createrepo )
e_date=$( /usr/bin/which date )
e_systemctl=$( /usr/bin/which systemctl )
e_time=$( /usr/bin/which time )
e_reposync=$( /usr/bin/which reposync )

# Proxy server
h_proxy=CHANGEME

# Proxy user/password
s_proxy_user=CHANGEME
s_proxy_password=CHANGEME

###
### DERIVED VARIABLES
###

s_daynum=$( ${e_date} +%d)
s_dayword=$( ${e_date} +%a)


###
### FUNCTIONS
###

# Restore the local package repository information.
reset_dl_repos () {
  ${e_rm} -rf /etc/yum.repos.d
  ${e_mv} /etc/yum.repos.d.reposync /etc/yum.repos.d
}

# Restore the local yum.conf file.
reset_yum_conf () {
  ${e_mv} /etc/yum.conf.reposync /etc/yum.conf
}

# Move the normal repository information out of the way, and insert
# information for the public repositories.
set_dl_repos () {

  ${e_mv} /etc/yum.repos.d /etc/yum.repos.d.reposync
  ${e_mkdir} -m 0755 -p /etc/yum.repos.d/

  cat <<EOREPOS >/etc/yum.repos.d/ext_source.repo
[ol7_latest]
name=Oracle Linux \$releasever Latest (\$basearch)
baseurl=http://public-yum.oracle.com/repo/OracleLinux/OL7/latest/\$basearch/
gpgkey=file:///\${d_rpm-gpg}/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
proxy=http://\${h_proxy}

[ol7_UEKR3]
name=Latest Unbreakable Enterprise Kernel Release 3 for Oracle Linux \$releasever (\$basearch)
baseurl=http://public-yum.oracle.com/repo/OracleLinux/OL7/UEKR3/\$basearch/
gpgkey=file:///\${d_rpm-gpg}/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
proxy=http://\${h_proxy}

[ol7_UEKR4]
name=Latest Unbreakable Enterprise Kernel Release 4 for Oracle Linux \$releasever (\$basearch)
baseurl=http://public-yum.oracle.com/repo/OracleLinux/OL7/UEKR4/\$basearch/
gpgkey=file:///\${d_rpm-gpg}/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
proxy=http://\${h_proxy}

[ol7_optional_latest]
name=Oracle Linux \$releasever Optional Latest (\$basearch)
baseurl=http://public-yum.oracle.com/repo/OracleLinux/OL7/optional/latest/\$basearch/
gpgkey=file:///\${d_rpm-gpg}/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
proxy=http://\${h_proxy}

[ol7_addons]
name=Oracle Linux \$releasever Add ons (\$basearch)
baseurl=http://public-yum.oracle.com/repo/OracleLinux/OL7/addons/\$basearch/
gpgkey=file:///\${d_rpm-gpg}/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
proxy=http://\${h_proxy}

[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///\${d_rpm-gpg}/RPM-GPG-KEY-EPEL-7
proxy=http://\${h_proxy}

EOREPOS
}

# Move the normal yum.conf out of the way, and set a customized
# varient for downloading from public repositories.
set_yum_conf () {
 ${e_mv} /etc/yum.conf /etc/yum.conf.reposync

 cat <<EOCONF >/etc/yum.conf
[main]
cachedir=/var/cache/yum/\$basearch/\$releasever
keepcache=0
debuglevel=2
logfile=/var/log/yum.log
distroverpkg=redhat-release
tolerant=1
exactarch=1
obsoletes=1
gpgcheck=1
plugins=1

# Note: yum-RHN-plugin doesnt honor this.
metadata_expire=1h

#http_caching=packages
#proxy_url=http://${h_proxy}
#proxy_username=${s_proxy_user}
#proxy_password=${s_proxy_password}

# PUT YOUR REPOS HERE OR IN separate files named file.repo
# in /etc/yum.repos.d

EOCONF
}

update_manual () {

  # Update public repositories.
  # See http://www.artificialworlds.net/blog/2012/10/17/bash-associative-array-examples/
  # for notes on Associative Arrays ("hashes") in bash.
 
  declare -A a_destinations
  a_destinations[ol7_latest]=${d_repo_base}/OracleLinux/OL7/latest/x86_64
  a_destinations[ol7_UEKR3]=${d_repo_base}/OracleLinux/OL7/UEKR3/latest/x86_64
  a_destinations[ol7_UEKR4]=${d_repo_base}/OracleLinux/OL7/UEKR4/latest/x86_64
  a_destinations[ol7_optional_latest]=${d_repo_base}/OracleLinux/OL7/optional_latest/x86_64
  a_destinations[ol7_addons]=${d_repo_base}/OracleLinux/OL7/addons/x86_64
  a_destinations[epel]=${d_repo_base}/epel
 
  for s_repository in "${!a_destinations[@]}"
  do
 
    d_destination=${a_destinations[${s_repository}]}
 
    if [ ! -d "${d_destination}" ]
    then
      ${e_mkdir} --parents --mode=0755 ${d_destination}
    fi
 
    pushd ${d_destination}
 
    # Pull down the packages.
    ${e_reposync} \
      --delete \
      --newest-only \
      --downloadcomps \
      --repoid=${s_repository} \
      --download_path=${d_destination}
 
    # Does this repository have package groups?
    unset df_comps
    if [ -e "${d_destination}/comps.xml" ]
    then
      df_comps="--groupfile ${d_destination}/comps.xml"
    fi
 
    # Update the local repository metadata.
    ${e_createrepo} \
      --verbose \
      --workers 2 \
      ${df_comps} \
      --unique-md-filenames \
      --pretty \
      --revision $( ${e_date} +%Y%m%d ) \
      --database .
 
    popd
  done
}


###
### MAIN
###

# Only run on the seocnd Tuesday of the month, to align with Microsoft
# monthly patching.
if [[ ${s_daynum} > "07" ]] \
 && [[ ${s_daynum} < "15" ]] \
 && [ ${s_dayword} == "Tue" ] \
 || [ "${1}" == "now" ]
then

  set_yum_conf
  set_dl_repos
 
  yum clean all
 
  update_manual
 
  reset_yum_conf
  reset_dl_repos

fi
) >/var/log/localrepos.out 2>&1

