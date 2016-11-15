#!/bin/bash
#
# Run the sysctl command to immediately change the running system to match
# copied sysctl.conf file.

sysctl -w \
net.ipv4.ip_forward=0 \
net.ipv4.conf.all.accept_source_route=0 \
net.ipv4.conf.default.accept_source_route=0 \
net.ipv4.conf.all.accept_redirects=0 \
net.ipv4.conf.defautl.accept_redirects=0 \
net.ipv4.conf.all.send_redirects=0 \
net.ipv4.conf.defautl.send_redirects=0 \
net.ipv4.icmp_echo_ignore_broadcasts=1
