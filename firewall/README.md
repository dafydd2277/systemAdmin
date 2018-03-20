# Firewall Scripting

My first script, `firewall.sh`, was created out of my need to automate the installation of a firewall on a NAT gateway. It's a big block of ugly, but it does waht it needs to do.

The newer scripts, `prefix.sh`, `body.sh`, and `suffix.sh` were created to handle the problem of host-based firewalls on individual hosts within the enterprise. Most of these hosts only have a single interface, and most of these hosts have a single, well defined job. So, write a central script, here called `body.sh` that contains the custom `iptables` rules for the server type, and have body.sh call `prefix.sh` and `suffix.sh` for the global rules needed for each host.

Eventually, I'll migrate the NAT script into the prefix/body/suffix format, particularly if I wind up having a specific need.

