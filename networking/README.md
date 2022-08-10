# Notes on Networking

## Creating a bonded network.

The first important note is to make sure that the switch is also
configured for the kind of bond you're setting up.


### References
[Network Manager](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-starting_networkmanager)
[nmcli bonding](https://www.thegeekdiary.com/centos-rhel-7-how-to-create-an-interface-bonding-nic-teaming-using-nmcli/)
[DHCP](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/configuring_the_dhcp_client_behavior)

### Commands

```
yum list NetworkManager
```

Install NetworkManager, if necessary.

```
systemctl enable NetworkManager
systemctl start NetworkManager
systemctl -l status NetworkManager

BONDNAME=bond0
IFACE1=eno1
IFACE2=eno2

nmcli con del ${BONDNAME}
nmcli con del ${IFACE1}
nmcli con del ${IFACE2}


nmcli con add type bond \
  con-name ${BONDNAME} \
  ifname ${BONDNAME} \
  bond.options "mode=active-backup,miimon=100" \
  ipv4.method auto \
  ipv4.dhcp-timeout infinity
```

`ipv4.method auto` sets the bond for DHCP.

For LACP, use these bond options:

`mode=802.3ad,miimon=100,lacp_rate=fast,xmit_hash_policy=layer2+3`


```
nmcli con add type bond-slave ifname ${IFACE1} master ${BONDNAME}

nmcli con add type bond-slave ifname ${IFACE2} master ${BONDNAME}

nmcli con
```

`nmcli con`, without further options, will list the current connections.
`nmcli dev show` will list devices.

The active slave and dhcp timeout settings aren't needed for LACP or static
IP addresses, respectively.

```
nmcli dev mod ${BONDNAME} \
  +bond.options "active_slave=${IFACE1}"

nmcli con

systemctl restart network

ip address show dev ${BONDNAME}
```

If you want the bond to be static, use the following. This can be done
after the above commands. You're just changing existing settings.

```
nmcli con mod $BONDNAME \
  ipv4.method static \
  ipv4.dhcp-timeout "" \
  ipv4.address 139.181.76.135/22 \
  ipv4.gateway 139.181.79.254 \
  ipv4.dns 147.34.2.16,137.202.23.16,137.202.187.16

nmcli con show $BONDNAME

systemctl restart network

ip address show dev ${BONDNAME}
```

