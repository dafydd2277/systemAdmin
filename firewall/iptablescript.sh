#! /bin/bash
#set -x
#
# Author: David Barr
# Source: https://github.com/dafydd2277/systemAdmin/tree/master/firewall
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
# 2015-01-21 Original addition to github
#
# I wrote this to keep track of my firewall settings as I set up the host that
# stands between my home network and the outside world. Essentially, this
# is so I don't have to remember everything I do or don't want to filter.
#
# You need to set your internal and external interfaces before you use this
# script. See s_int_if and s_ext_if, in the next section. If you choose to use
# SNAT over MASQUERADE, set s_ext_ip, as well.
#
# Also, I have comments about several ideas that I might or might not
# implement. I haven't placed variables in all those ideas. You can't lose by
# having a good look through the script and figuring out what everything
# does.

###
### Explicit variables
###

e_chkconfig=/sbin/chkconfig
e_date=/bin/date
e_echo=/bin/echo
e_grep=/bin/grep
e_iptables=/sbin/iptables
e_ip6tables=/sbin/ip6tables
e_sed=/sbin/sed
e_service=/sbin/service

s_ext_if=<external interface>
s_ext_ip=<external IP address>
s_int_if=<internal interface>
s_int_subnet=<internal subnet>
s_int_prefix=<internal netmask as an integer, eg. 24>


###
### Main
###

# Make sure the kernel pieces are working.

if [ $(cat /proc/sys/net/ipv4/ip_forward) -ne 1 ]
then
  ${e_echo} "Setting /proc/sys/net/ipv4/ip_forward."
  ${e_echo} 1 > /proc/sys/net/ipv4/ip_forward
fi

${e_grep} -q "net.ipv4.ip_forward = 1" /etc/sysctl.conf 
if [ $? -ne 0 ]
then
  ${e_echo} "Modifying sysctl.conf"
  l_date=$(${e_date} +%Y%m%d)
  ${e_sed} --in-place=.${l_date} \
    "s/^net\.ipv4\.ip_forward.*/net.ipv4.ip_forward = 1" \
    /etc/sysctl.conf
fi


##### Start the services #####
${e_echo} "Start the services."

${e_chkconfig} iptables on
${e_service} iptables restart

${e_chkconfig} ip6tables on
${e_service} ip6tables restart


##### Drop everything in IPv6, and move on... #####
${e_echo} "Drop all of IPv6."
${e_ip6tables} --policy INPUT DROP
${e_ip6tables} --flush INPUT

${e_ip6tables} --policy FORWARD DROP
${e_ip6tables} --flush FORWARD

${e_ip6tables} --policy OUTPUT ACCEPT
${e_ip6tables} --flush OUTPUT


##### Basic policies #####
${e_echo} "Basic Policies"

${e_iptables} --policy INPUT DROP
${e_iptables} --flush INPUT

${e_iptables} --policy OUTPUT ACCEPT
${e_iptables} --flush OUTPUT

${e_iptables} --policy FORWARD DROP
${e_iptables} --flush FORWARD


##### NAT and forwarding. #####
${e_echo} "NAT and forwarding."

${e_iptables} --table nat --flush

${e_iptables} --table nat --append POSTROUTING --out-interface ${s_ext_if} \
  --jump MASQUERADE
#${e_iptables} --table nat --append POSTROUTING --out-interface ${s_ext_if} \
#  --jump SNAT --to ${s_ext_ip}


##### Localhost, lo #####
${e_echo} "Localhost, lo"

${e_iptables} --append INPUT --in-interface lo --jump ACCEPT


##### Internal network, ${s_int_if}, INPUT #####
${e_echo} "Internal network, ${s_int_if}, INPUT"

# Log everything
#${e_iptables} --append INPUT --in-interface ${s_int_if} --jump LOGGING

${e_iptables} --append INPUT --in-interface ${s_int_if} --jump ACCEPT

# Outbound connections from ${s_int_if} to ${s_ext_if}.
${e_iptables} --append FORWARD --in-interface ${s_int_if} \
  --out-interface ${s_ext_if} --jump ACCEPT


##### External network, ${s_ext_if}, INPUT ##### 
${e_echo} "Exernal network, ${s_ext_if}, INPUT"

# Log everything
#${e_iptables} --append INPUT --in-interface ${s_ext_if} --jump LOGGING

# Accept existing connections.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --match state \
  --state ESTABLISHED,RELATED --jump ACCEPT

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

# Politely reject packets to other privileged ports.
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol udp \
  --match udp --dport 0:1023 --jump REJECT --reject-with icmp-port-unreachable
${e_iptables} --append INPUT --in-interface ${s_ext_if} --protocol tcp \
  --match tcp --dport 0:1023 --tcp-flags SYN,RST,ACK SYN --jump REJECT \
  --reject-with icmp-port-unreachable

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
${e_iptables} --append INPUT --in-interface ${s_ext_if} --jump LOGGING


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
${e_echo} "Forwarding"

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
${e_iptables} --append FORWARD --source ${s_int_subnet}/${s_int_prefix} \
  --in-interface ${s_ext_if} --jump DROP

# Log the remainder.
#${e_iptables} --append FORWARD --in-interface ${s_ext_if} --jump LOGGING

# Throttle the logging.
${e_iptables} --append LOGGING --match limit --limit 15/minute --jump LOG \
  --log-level 7 --log-prefix "Dropped by iptables: "
${e_iptables} --append LOGGING --jump DROP



##### Final clean up. #####
${e_echo} "Save tables."

${e_service} iptables save
${e_service} ip6tables save

