#! /bin/bash
set -x
#
# Author: David Barr
# Source: https://github.com/dafydd2277/systemAdmin/
#
# Items marked FIXME require customization for your environment.
#
# This script needs further work on distinguishing RHEL 6 and RHEL 7.
# Scripting is always a work in progress.

###
### USAGE VALIDATIONS
###

if [ "$(id -u)" -ne 0 ]
then
  echo "Must be run as root."
  exit 1
fi

###
### EXPLICIT VARIABLES
###


###
### DERIVED VARIABLES
###

# GET THE GLOBAL VARIABLES
source <( $( /usr/bin/which curl ) -sS \
  https://raw.githubusercontent.com/dafydd2277/systemAdmin/master/scripting/globalvars.sh )
i_exit_code=$?
if [ "${i_exit_code}" -ne 0 ]
then
  return $i_exit_code
fi


###
### MAIN
###

# Execute the general rules that come before this custom block.
source <( ${e_curl} -sS \
  https://raw.githubusercontent.com/dafydd2277/systemAdmin/master/firewall/prefix.sh )
i_exit_code=$?
if [ "${i_exit_code}" -ne 0 ]
then
  return $i_exit_code
fi


# Ports opened for Oracle GRID/RDBMS
# https://docs.oracle.com/cd/B28359_01/install.111/b32002/app_port.htm#LADBI467
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 1158 \
  --jump ACCEPT
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 1521 \
  --jump ACCEPT
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 1630 \
  --jump ACCEPT
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 3938 \
  --jump ACCEPT
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 5520 \
  --jump ACCEPT
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 5540 \
  --jump ACCEPT

# Port opened for OMS control server to OEM agent
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 3872 \
  --jump ACCEPT


# Execute the general rules that come after this custom block.
source <( ${e_curl} -sS \
  https://raw.githubusercontent.com/dafydd2277/systemAdmin/master/firewall/suffix.sh )
i_exit_code=$?
if [ "${i_exit_code}" -ne 0 ]
then
  return $i_exit_code
fi

set +x


