#! /bin/bash
#set -x
#
# Author: David Barr
# Source: https://github.com/dafydd2277/systemAdmin/tree/master/firewall
#
# 2018-03-06 Shuffled some rules and added some ideas from
#
# https://www.cyberciti.biz/tips/linux-iptables-10-how-to-block-common-attack.html
# https://www.cyberciti.biz/tips/linux-iptables-8-how-to-avoid-spoofing-and-bad-addresses-attack.html
#
# Also, added package testing to use iptables in RHEL 7. I don't think
# is there, yet.
#
# 2015-02-18 Added some ideas.
#
# I added the packet logging ideas from
# http://www.thegeekstuff.com/scripts/iptables-rules
# and the DNS request rate limiting ideas from
# https://isc.sans.edu/diary/DNS-based+DDoS/19351
# and the second answer at
# http://serverfault.com/questions/418810/public-facing-recursive-dns-servers-iptables-rules
#
#
# 2015-01-21 Original addition to github
#
# I wrote this to keep track of my firewall settings as I set up the
# host that stands between my home network and the outside world.
# Essentially, this is so I don't have to remember everything I do or
# don't want to filter.
#
# You need to set your internal and external interfaces before you use
# this script. See s_int_if and s_ext_if, in the next section. If you
# choose to use SNAT over MASQUERADE, set s_ext_ip, as well.
#
# Also, I have comments about several ideas that I might or might not
# implement. I haven't placed variables in all those ideas. You can't
# lose by having a good look through the script and figuring out what
# everything does.

###
### EXPLICIT VARIABLES
###

s_ext_if=<external interface>
s_ext_ip=<external IP address>
s_int_if=<internal interface>
s_int_subnet=<internal subnet>
s_int_cidr=<internal netmask as an integer, eg. 24>


###
### DERIVED VARIABLES
###

s_old_path=${PATH}
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
export PATH

if [ -f /etc/os-release ]
then
  source /etc/os-release
fi

e_date=$( /usr/bin/which date )
# Use the shell builtin echo
e_grep=$( /usr/bin/which grep )
e_rpm=$( /usr/bin/which rpm )
e_sed=$( /usr/bin/which sed )

case ${VERSION_ID} in
  "6")
    e_chkconfig=$( /usr/bin/which chkconfig )
    e_service=$( /usr/bin/which service )
    ;;
  "7")
    e_systemctl=$( /usr/bin/which systemctl )

    ${e_rpm} -q iptables iptables-services >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
      yum -y install iptables iptables-services
      if [ $? -ne 0 ]
        echo "Installation of iptables or iptables-service failed."
        return 1
      fi
    fi
    ;;
esac

e_iptables=$( /usr/bin/which iptables )
e_ip6tables=$( /usr/bin/which ip6tables )

PATH=${s_old_path}
export PATH


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
  l_date=$( ${e_date} +%Y%m%d_%H%M )
  ${e_sed} --in-place=.${l_date} \
    "s/^net\.ipv4\.ip_forward.*/net.ipv4.ip_forward = 1" \
    /etc/sysctl.conf
  cat <<EOMARTIANS >>/etc/sysctl.conf
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1
EOMARTIANS

fi


##### Start the services #####
echo "Start the services."

unset i_result
case ${VERSION_ID} in
  "6")
    ${e_chkconfig} iptables on
    i_result=$?
    ${e_service} iptables restart
    i_result=$?
    
    ${e_chkconfig} ip6tables on
    i_result=$?
    ${e_service} ip6tables restart
    i_result=$?

    if [ ${i_result} -ne 0 ]
    then
      echo "Failed to start iptables or ip6tables."
      return 1
    fi
    ;;
  "7")
    ${e_systemctl} stop firewalld.service
    i_result=$?
    ${e_systemctl} mask firewalld.service
    i_result=$?

    if [ ${i_result} -ne 0 ]
    then
      echo "Failed to disable firewalld."
      return 1
    fi

    ${e_systemctl} enable iptables.service
    i_result=$?
    ${e_systemctl} restart iptables.service
    i_result=$?

    if [ ${i_result} -ne 0 ]
    then
      echo "Failed to start iptables or ip6tables."
      return 1
    fi
    ;;
esac


##### Drop everything in IPv6, and move on... #####
echo "Drop all of IPv6."
${e_ip6tables} --policy INPUT DROP
${e_ip6tables} --flush INPUT

${e_ip6tables} --policy FORWARD DROP
${e_ip6tables} --flush FORWARD

${e_ip6tables} --policy OUTPUT ACCEPT
${e_ip6tables} --flush OUTPUT


##### Basic policies #####
echo "Basic Policies"

${e_iptables} --policy INPUT DROP
${e_iptables} --flush INPUT

${e_iptables} --policy OUTPUT ACCEPT
${e_iptables} --flush OUTPUT

${e_iptables} --policy FORWARD DROP
${e_iptables} --flush FORWARD


##### NAT and forwarding. #####
echo "NAT and forwarding."

${e_iptables} --table nat --flush

${e_iptables} --table nat --append POSTROUTING --out-interface ${s_ext_if} \
  --jump MASQUERADE
#${e_iptables} --table nat --append POSTROUTING --out-interface ${s_ext_if} \
#  --jump SNAT --to ${s_ext_ip}


##### Localhost, lo #####
echo "Localhost, lo"

${e_iptables} --append INPUT --in-interface lo --jump ACCEPT


##### Internal network, ${s_int_if}, INPUT #####
echo "Internal network, ${s_int_if}, INPUT"

# Acceipt anything from the internal network.
${e_iptables} --append INPUT --in-interface ${s_int_if} --jump ACCEPT

# Outbound connections from ${s_int_if} to ${s_ext_if}.
${e_iptables} --append FORWARD --in-interface ${s_int_if} \
  --out-interface ${s_ext_if} --jump ACCEPT


##### External network, ${s_ext_if}, INPUT ##### 
echo "Exernal network, ${s_ext_if}, INPUT"

# Log everything
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --jump LOGGING

# Accept existing connections.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --match state \
  --state ESTABLISHED,RELATED --jump ACCEPT

# Drop any new connection attempt that doesn't start with a SYN packet.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
  --match tcp --dport 0:1023 --tcp-flags SYN,RST,ACK SYN --jump DROP
${e_iptables} --append INPUT --protocol tcp ! --syn --match state \
  --state NEW --jump DROP

# Drop any fragmented packets
${e_iptables} --append INPUT --in-interface ${s_ext_if} --fragment \
  --jump DROP

# Drop malformed "XMAS" packets
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
  --tcp-flags ALL ALL --jump DROP

# Drop malformed NULL packets.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
  --tcp-flags ALL NONE --jump DROP

# Drop anything from a spoofed network.
# Feel free to add attempts to add internal net IP addresses coming in
# to your external interface.
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


# FTP is TCP only.
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 21 --jump ACCEPT

# SSH is TCP only.
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 22 --jump ACCEPT

# SMTP
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
#  --match udp --destination-port 25 --jump ACCEPT
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 25 --jump ACCEPT

# Allow incoming DNS requests and replies.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
  --match udp --destination-port 53 --match hashlimit \
  --hashlimit-name DNSinUDP --hashlimit-upto 20/minute --hashlimit-burst 5 \
  --jump ACCEPT

${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
  --match tcp --destination-port 53 --match hashlimit \
  --hashlimit-name DNSinTCP --hashlimit-upto 20/minute --hashlimit-burst 5 \
  --jump ACCEPT

# Insecure HTTP
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
#  --match udp --destination-port 80 --jump ACCEPT
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 80 --jump ACCEPT

# POP3, TCP only
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 110 --jump ACCEPT

# SFTP
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
#  --match udp --destination-port 115 --jump ACCEPT
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 115 --jump ACCEPT

# Allow incoming NTP requests and replies.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
  --match udp --destination-port 123 --jump ACCEPT
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
  --match tcp --destination-port 123 --jump ACCEPT
#ip6tables --append INPUT --in-interface ${s_ext_if} --protocol udp \
#  --match udp --destination-port 123 --jump ACCEPT
#ip6tables --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 123 --jump ACCEPT

# HTTPS
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
#  --match udp --destination-port 443 --jump ACCEPT
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 443 --jump ACCEPT

# Secure SMTP, pop3s
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
#  --match udp --destination-port 995 --jump ACCEPT
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 995 --jump ACCEPT

# BZFlag server
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
#  --match udp --destination-port 5154 --jump ACCEPT
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 5154 --jump ACCEPT

# Gnutella P2P
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
#  --match udp --destination-port 6346 --jump ACCEPT
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
#  --match tcp --destination-port 6346 --jump ACCEPT

# Drop BOOTP and NETBIOS broadcasts
${e_iptables} --append INPUT --in-interface ${s_interface} --protocol udp \
 --match udp --destination-port 67 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_interface} --protocol udp \
 --match udp --destination-port 137 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_interface} --protocol udp \
 --match udp --destination-port 138 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_interface} --protocol udp \
 --match udp --destination-port 1947 --jump DROP

# Politely reject packets to other privileged ports.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
  --match udp --dport 0:1023 --jump REJECT --reject-with icmp-port-unreachable
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
  --match tcp --dport 0:1023 --jump REJECT --reject-with icmp-port-unreachable

# Drop packets to other, unprivileged ports.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
 --match udp --dport 1025:65535 --jump DROP
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
 --match tcp --dport 1025:65535 --jump DROP

# Accept pings. Drop all other ICMP
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol icmp \
  --match icmp --icmp-type echo-reply --jump ACCEPT
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol icmp \
  --match icmp --jump DROP

# Log the remainder
# Log the remainder before we drop them.
# RHEL 7 family dropped logging from iptables. :-(
if [ "${VERSION_ID}" -lt 7 ]
then
  ${e_iptables} --append INPUT --match limit --limit 4/minute --jump LOG \
   --log-level warn --log-prefix "Dropped by iptables: "
fi


##### OUTPUT #####
# Throttle outbound DNS
${e_iptables} --append OUTPUT --protocol udp --match udp \
  --destination-port 53 --match hashlimit --hashlimit-name DNSoutUDP \
  --hashlimit-upto 20/minute --hashlimit-burst 5 --jump ACCEPT
${e_iptables} --append OUTPUT --protocol tcp --match tcp \
  --destination-port 53 --match hashlimit --hashlimit-name DNSoutTCP \
  --hashlimit-upto 20/minute --hashlimit-burst 5 --jump ACCEPT 

# Accept everything else.
${e_iptables} --append OUTPUT --out-interface ${s_int_if} --jump ACCEPT
${e_iptables} --append OUTPUT --out-interface ${s_ext_if} --jump ACCEPT
${e_iptables} --append OUTPUT --out-interface lo --jump ACCEPT

# Log the remainder, for future rules.
${e_iptables} --append OUTPUT --jump LOGGING


##### FORWARD #####
echo "Forwarding"

# Log everything
#${e_iptables} --append FORWARD --jump LOGGING

# Forward replies to outbound requests.
${e_iptables} --append FORWARD --in-interface ${s_ext_if} \
  --out-interface ${s_int_if} --match state --state ESTABLISHED,RELATED \
  --jump ACCEPT

# Forward requests to port 80 to the web server. Also requires a NAT and an
# INPUT rule.
#${e_iptables} --append FORWARD --in-interface ${s_ext_if} --protocol tcp \
#  --dport 80 --destination 192.168.0.1 --jump ACCEPT
#${e_iptables} --append FORWARD --in-interface ${s_ext_if} --protocol tcp \
#  --dport 443 --destination 192.168.0.1 --jump ACCEPT

# Drop anything from the outside that looks like it's using an inside IP
# address.
${e_iptables} --append FORWARD --source ${s_int_subnet}/${s_int_cidr} \
  --in-interface ${s_ext_if} --jump DROP

# Log the remainder.
#${e_iptables} --append FORWARD --in-interface ${s_ext_if} --jump LOGGING

# Throttle the logging.
${e_iptables} --append LOGGING --match limit --limit 15/minute --jump LOG \
  --log-level 7 --log-prefix "Dropped by iptables: "
${e_iptables} --append LOGGING --jump DROP



##### Final clean up. #####
echo "Save tables."

case ${VERSION_ID} in
  "6")
    ${e_service} iptables save
    ${e_service} ip6tables save
    ;;
  "7")
    ${e_systemctl} save iptables
    ;;
esac

${e_iptables} -L -v -n --line-numbers

