# Setting up DNS

This is basically a copy and paste of a text document I did years ago. I've done some markdown for readability, but this still needs a good going over and improvement.


## Opening Notes

DNS is trickier to explain than DHCP. The syntax used in its files is less intuitive and easier to break. I will strongly recommend anyone who starts regularly maintaining a DNS server be well versed in the underlying theory. My two favorites are
 
 - http://www.linuxhomenetworking.com/wiki/index.php/Quick_HOWTO_:_Ch18_:_Configuring_DNS
 - http://rscott.org/dns/
 
For the most part, maintaining a DNS environment is a case of looking at existing entries and copying them for the new entries.
 
The first note is that named runs in a chroot environment. Its configuration files are modified by the named-chroot package to reside in /var/named/chroot/. This reduces the risk of hacking.
 
Second, in trying to solve the a DNS delay problem, I researched and implemented an extensive logging system. Let's look at this piece of `var/named/chroot/etc/named.conf`, first.

```
logging {
  channel "namedlog" {
    file "/var/log/named/named.log";
    severity info;
    print-time yes;
    print-category yes;
    print-severity yes;
  };
  channel "querylog" {
    file "/var/log/named/query.log";
    severity info;
    print-time yes;
    print-category yes;
    print-severity yes;
  };
  channel "lamerlog" {
    file "/var/log/named/lamer.log";
    severity info;
    print-time yes;
    print-category yes;
    print-severity yes;
  };
  category default { namedlog; };
  category queries { null; };
#  category queries { querylog; };
  category lame-servers { null; };
#  category lame-servers { lamerlog; };
};

```


You can see that I use three syslog `local` facilities to track three sets of DNS information. DNS system messages go to the namedlog channel, queries can go to a query log, and badly formed requests can be redirected to a seperate "lamerlog." In normal conditions, as you can see from the commented lines, I don't generally log good or bad queries at all. For more information on the specific options, have a look at the links I mentioned.
 
Third, the "zone files," the files that actually encode the forward and reverse DNS maps are identified by an integer serial number. Master servers will not update their internal databases with new informtion, and client DNS servers will not know to mass copy the zones from the Master unless it finds a zone file serial number larger than what it has in current cache. In keeping with common practice on other DNS installations, the serial number for my DNS zone files is in the format of YYYYMMDDnn. That's the four-digit year, two-digit month, two-digit day, and a two-digit increment number. Keeping this value up to date and in this format every time you modify a file will keep the zones up to date when you restart the servers.
 

## Package installation

```bash
yum install bind bind-chroot
```


## named.conf

Let's look at part of /var/named/chroot/etc/named.conf for a DNS server in a Master configuration.

```
zone "sub1.example.com"{
  type master;
  allow-query { any; };
  file "sub1.zone";
  forwarders {};
};

zone "sub2.example.com"{
  type master;
  notify no;
  allow-query { any; };
  file "sub2.zone";
  forwarders {};
};

zone "sub3.example.com"{
  type master;
  allow-query { any; };
  file "sub3.zone";
  forwarders {};
};


zone "0.168.192.in-addr.arpa"{
  type master;
  allow-query { any; };
  file "192.168.0.zone";
  forwarders {};
};

zone "2.168.192.in-addr.arpa"{
  type master;
  allow-query { any; };
  file "192.168.2.zone";
  forwarders {};
};

```


And the same file from another DNS server, which acts as a Client (slave) of the first. The keyword `masters` identifies the IP addresses of the Master DNS servers allowed to update the zone files on this Client.

```
zone "sub1.example.com"{
  type slave;
  notify no;
  allow-query { any; };
  file "sub1.zone";
  masters { 192.168.0.1; };
  forwarders {};
};

zone "sub2.example.com"{
  type slave;
  notify no;
  allow-query { any; };
  file "sub2.zone";
  masters { 192.168.0.1; };
  forwarders {};
};

zone "sub1.example.com"{
  type slave;
  notify no;
  allow-query { any; };
  file "sub2.zone";
  masters { 192.168.0.1; };
  forwarders {};
};


zone "0.168.192.in-addr.arpa"{
  type slave;
  allow-query { any; };
  file "192.168.0.zone";
  masters { 192.168.0.1; };
  forwarders {};
};

zone "2.168.192.in-addr.arpa"{
  type slave;
  allow-query { any; };
  file "192.168.2.zone";
  masters { 192.168.0.1; };
  forwarders {};
};

```


While the "master" type configuration entries identify the file to read from, the "slave" type configuration entries identify the file to write to. Further, the files on the master are kept in /var/named/chroot/var/named, while the files on the slave are kept in /var/named/chroot/var/named/slaves. The slave files should never need to be manually modified.
 
Also, note that the slave configuration notes the IP address of the associated master DNS servers. A slave could take entries from several different masters, if needed.
 

## Reverse Zones

 Next, let's look at the header section of one of the reverse zone files:

```
$ORIGIN 0.168.192.in-addr.arpa.
$TTL  86400
@ IN  SOA dns1.example.com. root.dns1.example.com. (
                                      2015010301 ; yyyymmddnn
                                      3600       ; Refresh 1h
                                      1800       ; Retry   30m
                                      86400      ; Expire  1d
                                      1800 )     ; Minimum 30m
;
@ IN  NS  dns1.example.com.
@ IN  NS  dns2.example.com.

```


The $ORIGIN identifies which subnet or subdomain is defined in the file, in DNS reverse notation. The SOA record identifies the name server, email contact, and various settings. You'll see here that the first integer setting is the serial number I mentioned before. Then, we see references to the two Name Servers (NS). The @ symbol is a single-character variable representing the value of $ORIGIN.
 
 Next, let's look at some specific entries:

```
21  IN  PTR host1.sub1.example.com.
22  IN  PTR host2.sub1.example.com.
23  IN  PTR host1.sub2.example.com.
24  IN  PTR host2.sub2.example.com.
25  IN  PTR host3.sub2.example.com.

```


`PTR` (pointer) records (See table 18.5 of the linuxhomenetworking.com link.) identify reverse associations. That is to say, the final octet of the IP address is listed and associated with a hostname. Note the TLD dot at the end of each hostname. Forgetting this will break the zone file and require another edit. SOA, NS, and PTR records are the only permitted record types in a reverse zone file.
 
## Forward Zones

Next, we'll look at a forward zone file. These map hostnames to IP addresses, which is the more common translation. Here's the header:

```
$ORIGIN sub1.example.com.
$TTL  86400
@   IN  SOA dns1.example.com. root.dns1.example.com. (
                                      2015010301 ; Serial yyyymmddnn
                                      3600       ; Refresh 1h
                                      1800       ; Retry   30m
                                      86400      ; Expire  1d
                                      1800 )     ; Minimum 30m
;
@   IN  NS  dns1.example.com.
ns  IN  CNAME dns1.example.com.
@   IN  NS  dns2.example.com.

```


As you can see, it is identical to the reverse zone file. One additional item is our first CNAME record. A CanonicalNAME record translates one FQDN to another, canonical, FQDN for the host. In this case, if a host were to request information on `ns.sub1.example.com`, that host would receive a forward pointer and information for dns1.example.com, instead.
 
 Here are some records, including some more CNAMEs typical for an Oracle GRID/RAC cluster.

```
host1        IN  A      192.168.0.21
host2        IN  A      192.168.0.22
;
oracle1      IN  A      192.168.0.151
oracle2      IN  A      192.168.0.152
;
oracle1-vip  IN  A      192.168.0.161
oracle1vip   IN  CNAME  oracle1-vip
oracle2-vip  IN  A      192.168.0.162
oracle2vip   IN  CNAME  oracle2-vip
;
host240      IN  A      192.168.0.240
host241      IN  A      192.168.0.241
host242      IN  A      192.168.0.242
host243      IN  A      192.168.0.243
host244      IN  A      192.168.0.244
;
oracle3      IN  A      192.168.0.251
oracle31     IN  CNAME  oracle3

```

Here, A records translate hostnames to IP addresses.




