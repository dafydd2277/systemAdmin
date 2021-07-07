# Basic Notes

>2021-07-06 - This is going to be turned into configuration for a containerized
instance in the next couple months. I hope.


## Installation

- Install the packages.

```bash
yum -y install httpd httpd-manual mod_ssl
```

- Adjust the firewall.

Remember that the `external` zone has `masquerade` on by default. And, you
don't want the host externally accessible via SSH. Manage this host from the
internal network only.

```
firewall-cmd \
  --permanent \
  --zone=external \
  --add-service=http \
  --add-service=https \
  --remove-service=ssh

firewall-cmd --reload

firewall-cmd \
  --zone=external \
  --list-all
```


## Force redirection of all traffic to https.

From http://httpd.apache.org/docs/2.2/rewrite/avoid.html

```apache
<VirtualHost *:80>
ServerName www.example.com
Redirect / https://www.example.com/
</VirtualHost >

<VirtualHost *:443>
ServerName www.example.com

# ... SSL configuration goes here
</VirtualHost >
```

Each virtual host would have to have a similar `<VirtualHost *:80>`
redirection block.


## Showing directories based on source IP address

- https://serverfault.com/a/776231
- https://blogs.apache.org/httpd/entry/new_in_httpd_2_4
- http://httpd.apache.org/docs/2.4/expr.html


## GNU Terry Pratchett

From http://www.gnuterrypratchett.com/

Add the header `X-Clacks-Overhead: GNU Terry Pratchett` to every response.

```apache
<IfModule headers_module>
  header set X-Clacks-Overhead "GNU Terry Pratchett"
</IfModule>
```
