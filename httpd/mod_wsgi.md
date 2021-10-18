# Reference Notes for mod_wsgi

https://modwsgi.readthedocs.io/en/master/user-guides/quick-configuration-guide.html

http://wsgi.tutorial.codepoint.net/ - Uses its own baby webserver. Which might
be handy for DEV.

https://modwsgi.readthedocs.io/en/master/user-guides/configuration-guidelines.html
suggests multiple scripts could be managed through Apache’s
`WSGIScriptAlias` functionality, instead of having to make the main script
a wrapper.

https://dev.mysql.com/doc/connector-python/en/connector-python-examples.html
- Connect to MySQL.

https://mariadb.com/resources/blog/how-to-connect-python-programs-to-mariadb/
- Connect to MariaDB.

## Sample Applications

```
def application ( environment, start_response ):
  status = '200 OK'
  response = str(environment)

  response_headers = [
                       ( 'Content-Type', 'text/plain' ),
                       ( 'Content-Length', str(len(response)) ),
                       ( 'X-Clacks-Overhead', 'GNU Terry Pratchett' )
                     ]

  start_response ( status, response_headers )
  return [ response ]
```

http://markfrimston.co.uk/articles/30/quick-python-web-setup-for-apache

https://modwsgi.readthedocs.io/en/master/user-guides/installation-on-macosx.html
- This is part of the general WSGI documentation. This seems like the best to
read.
