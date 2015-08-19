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

Each virtual host would have to have a similar `<VirtualHost *:80>` redirection block.


## GNU Terry Pratchett

From http://www.gnuterrypratchett.com/

Add the header `X-Clacks-Overhead: GNU Terry Pratchett` to every response.

```apache
<IfModule headers_module>
  header set X-Clacks-Overhead "GNU Terry Pratchett"
</IfModule>
```

