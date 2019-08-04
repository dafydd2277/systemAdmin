#! /bin/bash
#set -x
#
# Author: David Barr
# Source: https://github.com/dafydd2277/systemAdmin/
#

###
### MAIN
###

case ${i_major_version} in
  5)
    echo "Oracle Linux 5 has been deprecated."
    echo "Please upgrade to Oracle linux 7."
    echo "No futher action will be taken."
    return 1
    ;;
  6)
    a_pkgs_to_install=( \
      iptables \
      iptables-ipv6 \
    )

    fn_global_install_packages
    if [ $? -ne 0 ]
    then
      echo "Package installation failed."
      return 1
    fi

    ##### Start the services #####
    echo "Start the services."
    ${e_chkconfig} iptables on
    ${e_service} iptables restart
    ${e_chkconfig} ip6tables on
    ${e_service} ip6tables restart

    ##### Drop everything in IPv6, and move on... #####
    echo "Drop all of IPv6."
    ${e_ip6tables} --policy INPUT DROP
    ${e_ip6tables} --flush INPUT
    ${e_ip6tables} --policy FORWARD DROP
    ${e_ip6tables} --flush FORWARD
    ${e_ip6tables} --policy OUTPUT ACCEPT
    ${e_ip6tables} --flush OUTPUT
    ;;
  7)
    a_pkgs_to_install=( \
      iptables \
      iptables-services \
    )

    fn_global_install_packages
    if [ $? -ne 0 ]
    then
      echo "Package installation failed."
      return 1
    fi

    ##### Stop firewalld #####
    echo "Stop firewalld."
    ${e_systemctl} stop firewalld 2>/dev/null
    ${e_systemctl} mask firewalld 2>/dev/null

    ##### Start the services #####
    echo "Start the services."
    ${e_systemctl} enable iptables
    ${e_systemctl} restart iptables
    ;;
esac



##### Basic policies #####
echo "Basic Policies"
${e_iptables} --policy INPUT DROP
${e_iptables} --flush INPUT
${e_iptables} --policy OUTPUT ACCEPT
${e_iptables} --flush OUTPUT
${e_iptables} --policy FORWARD DROP
${e_iptables} --flush FORWARD


# Accept all traffic from localhost
${e_iptables} --append INPUT --in-interface lo --jump ACCEPT

# Block attempts to use 127.0.0.1 from interfaces that are not
# localhost.
${e_iptables} --append INPUT ! --in-interface lo \
  --source 127.0.0.0/8 --jump DROP
${e_iptables} --append INPUT ! --in-interface lo \
  --destination 127.0.0.0/8 --jump DROP


# Block the "SACK panic"
$e_iptables} --append INPUT --protocol tcp \
  --match conntrack --ctstate NEW \
  --match tcpmss ! --mss 536:65535 \
  --jump REJECT --reject-with icmp-admin-prohibited

# Drop fragmented packets
${e_iptables} --append INPUT --fragment --jump DROP

# Drop incoming malformed NULL packets.
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE \
  --jump DROP

# Drop malformed "XMAS" packets
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --tcp-flags ALL ALL \
  --jump DROP

# Accept connections that start with this host.
${e_iptables} --append INPUT \
  --match state --state ESTABLISHED,RELATED \
  --jump ACCEPT

# Drop new incoming packets with FIN/RST/ACK but not SYN
${e_iptables} --append INPUT --protocol tcp \
  --match state --state NEW \
  --match tcp ! --tcp-flags FIN,SYN,RST,ACK SYN --jump DROP

# Only accept new connections that start with a SYN packet.
# (This is probably a tidier version of the previous rule.)
${e_iptables} --append INPUT --protocol tcp \
  ! --syn --match state --state NEW --jump DROP

# Accept RST,ACK acknowledgements
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG RST,ACK \
  --jump ACCEPT

# Accept PSH,ACK acknowledgements
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG PSH,ACK \
  --jump ACCEPT


# NFS is TCP only.
#${e_iptables} --append INPUT --protocol tcp \
#  --match tcp --destination-port 111 --jump ACCEPT
#${e_iptables} --append INPUT --protocol tcp \
#  --match tcp --destination-port 33100:33200 --jump ACCEPT
#${e_iptables} --append INPUT --protocol tcp \
#  --match tcp --destination-port 36000:36100 --jump ACCEPT


# SSH is TCP only.
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 22 --jump ACCEPT

