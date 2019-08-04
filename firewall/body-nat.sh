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

# Override any of these by setting them as environment variables.
# eg. `export s_ext_if=enp4s0`

# The name of the external interface
s_ext_if=${s_ext_if:-eth0}

# The name of the internal interface
s_int_if=${s_int_if:-eth1}
s_int_subnet=${s_int_subnet:-192.168.0.0}
s_int_mask=${s_int_mask:-24}

###
### DERIVED VARIABLES
###

# GET THE GLOBAL VARIABLES
source <( $( /usr/bin/which curl ) -sS https://raw.githubusercontent.com/dafydd2277/systemAdmin/master/scripting/globalvars.sh )
i_exit_code=$?
if [ "${i_exit_code}" -ne 0 ]
then
  return $i_exit_code
fi


###
### MAIN
###

# Make sure the kernel pieces are working.

if [ $(cat /proc/sys/net/ipv4/ip_forward) -ne 1 ]
then
  echo "Setting /proc/sys/net/ipv4/ip_forward."
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo 1 > /proc/sys/net/ipv4/conf/all/log_martians
  echo 1 > /proc/sys/net/ipv4/conf/default/log_martians
fi

${e_grep} -q "net.ipv4.ip_forward = 1" /etc/sysctl.conf 
if [ $? -ne 0 ]
then
  echo "Modifying sysctl.conf"
  ${e_sed} --in-place=.${s_dateref} \
    "s/^net\.ipv4\.ip_forward.*/net.ipv4.ip_forward = 1/" \
    /etc/sysctl.conf
  cat <<EOMARTIANS >>/etc/sysctl.conf
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOMARTIANS

fi


# Execute the general rules that come before this custom block.
source <( ${e_curl} -sS https://raw.githubusercontent.com/dafydd2277/systemAdmin/master/firewall/prefix.sh )
i_exit_code=$?
if [ "${i_exit_code}" -ne 0 ]
then
  return $i_exit_code
fi


##### NAT and forwarding. #####
echo "NAT and forwarding."

${e_iptables} --table nat --flush

${e_iptables} --table nat --append POSTROUTING \
  --out-interface ${s_ext_if} \
  --jump MASQUERADE


# Outbound connections from ${s_int_if} to ${s_ext_if}.
${e_iptables} --append FORWARD --in-interface ${s_int_if} \
  --out-interface ${s_ext_if} --jump ACCEPT


# Drop anything from the outside that looks like it's using an inside IP
# address.
${e_iptables} --append INPUT --in-interface ${s_ext_if} \
   --source ${s_int_subnet}/${s_int_mask} --jump DROP

# Drop anything from a spoofed network.
# One of these rules probably duplicates the rule immediately above.
# That's okay.
${e_iptables} --append INPUT --in-interface ${s_ext_if} \
  --source 0.0.0.0/8 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_ext_if} \
  --source 127.0.0.0/8 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_ext_if} \
  --source 10.0.0.0/8 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_ext_if} \
  --source 172.16.0.0/12 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_ext_if} \
  --source 192.168.0.0/16 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_ext_if} \
  --source 224.0.0.0/3 --jump DROP


# SMTP, including outbound relay
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 25 --jump ACCEPT
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 995 --jump ACCEPT


# Allow incoming DNS requests and replies, within limits.
${e_iptables} --append INPUT --protocol udp \
  --match udp --destination-port 53 \
  --match hashlimit --hashlimit-name DNSinUDP \
  --hashlimit-upto 20/minute --hashlimit-burst 5  --jump ACCEPT
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 53 \
  --match hashlimit --hashlimit-name DNSinTCP \
  --hashlimit-upto 20/minute --hashlimit-burst 5 --jump ACCEPT

# HTTP & HTTPS
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 80 --jump ACCEPT
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 443 --jump ACCEPT


##### FORWARD #####
# Forward replies to outbound requests.
${e_iptables} --append FORWARD \
  --in-interface ${s_ext_if} --out-interface ${s_int_if} \
  --match state --state ESTABLISHED,RELATED --jump ACCEPT


# Execute the general rules that come after this custom block.
source <( ${e_curl} -sS https://raw.githubusercontent.com/dafydd2277/systemAdmin/master/firewall/suffix.sh )
i_exit_code=$?
if [ "${i_exit_code}" -ne 0 ]
then
  return $i_exit_code
fi

set +x

