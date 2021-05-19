# Drop broadcasts not already accepted.
${e_iptables} --append INPUT \
  --match pkttype --pkt-type broadcast \
  --jump DROP

# Rate limit anything not already accepted.
${e_iptables} --append INPUT --protocol tcp \
  --match limit --limit 60/minute --limit-burst 100 \
  --jump ACCEPT


# Drop ECHO packets
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 7 \
  --jump DROP

# Drop BOOTP client broadcasts
${e_iptables} --append INPUT --protocol udp \
  --match udp --destination-port 67:68 \
  --jump DROP
${e_iptables} --append INPUT --protocol udp \
  --match udp --destination-port 137:138 \
  --jump DROP

# Drop NETBIOS discovery broadcasts
${e_iptables} --append INPUT --protocol udp \
  --match udp --destination-port 445 \
  --jump DROP

# Drop hlserver broadcasts
${e_iptables} --append INPUT --protocol udp \
  --match udp --destination-port 1947 \
  --jump DROP

# Drop Session Initiation Protocol
${e_iptables} --append INPUT --protocol udp \
  --match udp --destination-port 5060 --jump DROP
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --destination-port 5060 --jump DROP

# Drop Apple Multicast DNS
${e_iptables} --append INPUT --protocol udp \
  --match udp --destination-port 5353 --jump DROP

# Drop Dropbox LAN Sync broadcasts.
# (See https://help.dropbox.com/installs-integrations/sync-uploads/lan-sync-overview)
${e_iptables} --append INPUT --protocol udp \
  --match pkttype --pkt-type broadcast \
  --match udp --destination-port 17500 \
  --jump DROP

# Accept pings. Drop all other ICMP
${e_iptables} --append INPUT --protocol icmp \
  --match icmp --icmp-type echo-request --jump ACCEPT
${e_iptables} --append INPUT --protocol icmp \
  --match icmp --icmp-type any  --jump DROP


# DROP packets explicitly sent to 224.0.0.1, the multicast "broadcast"
# address.
${e_iptables} --append INPUT --destination 224.0.0.1/32 \
  --jump DROP


# Log the remainder before we drop them.
${e_iptables} --append INPUT \
  --match limit --limit 4/minute \
  --jump LOG --log-level info \
  --log-prefix "Dropped by iptables: "


# Politely reject packets to privileged ports not already opened.
${e_iptables} --append INPUT --protocol udp \
  --match udp --dport 0:1024 --jump REJECT \
  --reject-with icmp-port-unreachable
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --dport 0:1024 --jump REJECT \
  --reject-with icmp-port-unreachable

# Drop packets to other, unprivileged ports.
${e_iptables} --append INPUT --protocol udp \
  --match udp --dport 1025:65535 --jump DROP
${e_iptables} --append INPUT --protocol tcp \
  --match tcp --dport 1025:65535 --jump DROP


##### Final clean up. #####
${e_service} iptables save
${e_service} ip6tables save
${e_iptables} -L -vn --line-numbers

set +x
