# Notes on Networking

## Creating a bonded network.

The first important note is to make sure that the switch is also
configured for the kind of bond you're setting up.


### References
[Network Manager](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-starting_networkmanager)  
[nmcli bonding](https://www.thegeekdiary.com/centos-rhel-7-how-to-create-an-interface-bonding-nic-teaming-using-nmcli/)  
[DHCP](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/configuring_the_dhcp_client_behavior)  
[GRUB options](https://www.thegeekdiary.com/centos-rhel-7-how-to-modify-the-kernel-command-line/)

### Commands

#### Preparation

Install Network Manager

```
yum install NetworkManager

systemctl enable NetworkManager
systemctl start NetworkManager
systemctl -l status NetworkManager
```

Move the interface configuration files.

```
cd /etc/sysconfig/network-scripts

for file in ifcfg*
do
  mv -vi ${file} ${file}.back
done
```

Remove `net.ifnames=0` from the kernel boot parameters. It's not
supported in RHEL 7 and later for bonds.

```
grep ifnames /etc/default/grub
```

If the line exists, back up the file and edit `/etc/default/grub` to
remove the line. Then,

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

to set the new options. Making this change will require a reboot. See
the "GRUB options" link in the references section for more information.



#### Network Manager Command Line Interface

Note that `nmcli` only needs enough letters for a keyword to be unique.
So, `con`nection, `dev`ice, `del`ete, `mod`ify.


```
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

`mode=802.3ad,miimon=100,xmit_hash_policy=layer3+4`


```
nmcli con add type bond-slave ifname ${IFACE1} master ${BONDNAME}

nmcli con add type bond-slave ifname ${IFACE2} master ${BONDNAME}

nmcli con
```

`nmcli con`, without further options, will list the current connections.
`nmcli dev` will list devices.

The active slave option is only needed for `active-passive`.

```
nmcli dev mod ${BONDNAME} \
  +bond.options "active_slave=${IFACE1}"

nmcli con

systemctl restart network

ip addr show dev ${BONDNAME}
```

If you want the bond to be static, use the following. This can be done
after the above commands. You're just changing existing settings.

```
nmcli con mod ${BONDNAME} \
  ipv4.method static \
  ipv4.dhcp-timeout "" \
  ipv4.address 192.168.1.10/22 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns 192.168.1.1,192.168.1.2

nmcli con show ${BONDNAME}

systemctl restart network

ip addr show dev ${BONDNAME}
```

