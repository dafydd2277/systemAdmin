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

## Sample Application

This will give you a list, and a basic example of handling `POST` form
data.

```
from json import dumps
from os import path
from pprint import pformat
from urllib import parse

def application(environ, start_response):
  status = '200 OK'

  # The output must be a "sequence of byte string values," not a
  # string. See https://www.python.org/dev/peps/pep-3333/#a-note-on-string-types
  # and https://diveintopython3.net/strings.html#byte-arrays
  #output = b'Hello World!'
  #html = 'A complete HTML page assembled from parts.'
  #output = html.encode('utf-8')
  #output = environ['PATH_INFO'].encode('utf-8')
  # Or, use output as a list, like this:

  # show the environment:
  output = [b'<pre>']
  output.append(pformat(environ).encode('utf-8'))

  output.append(b'\n\nPATH_INFO: ' + environ['PATH_INFO'].encode('utf-8'))
  filepath, filename = path.split(environ['PATH_INFO'])
  filebase, fileext = path.splitext(filename)
  output.append(b'\nPath = ' + filepath.encode('utf-8'))
  output.append(b'\nFile = ' + filename.encode('utf-8'))
  output.append(b'\nFile Base = ' + filebase.encode('utf-8'))
  output.append(b'\nFile Ext = ' + fileext.encode('utf-8'))

  output.append(b'\n\nQUERY_STRING is\n' + environ['QUERY_STRING'].encode('utf-8'))
  queryDict = dict(parse.parse_qs(environ['QUERY_STRING']))
  queryDict = parse.parse_qs(environ['QUERY_STRING'])
  output.append(b'\n\nQUERY_STRING as a dict:\n')
  output.append(dumps(queryDict, sort_keys=True, indent=2).encode('utf-8'))

  output.append(b'</pre>')

  #create a simple form:
  output.append(b'\n\n<form method="post">')
  output.append(b'<input type="text" name="test">')
  output.append(b'<input type="submit">')
  output.append(b'</form>')

  if environ['REQUEST_METHOD'] == 'POST':
    # show form data as received by POST:
    output.append(b'\n\n<h1>FORM DATA</h1>')
    output.append(b'\n<pre>')
    output.append(pformat(environ['wsgi.input'].read()).encode('utf-8'))
    output.append(b'</pre>')

  # send results
  output_len = sum(len(line) for line in output)
  response_headers = [('Content-type', 'text/html'),
                      ('Content-Length', str(output_len)),
                      ('X-Clacks-Overhead', 'GNU Terry Pratchett')]

  start_response(status, response_headers)

  return output
```

[This link][ref101] predates httpd 2.4, so it's apache configuration
notes are out of date. Otherwise, it's a good beginning summary.
[This link][ref102] is part of the general WSGI documentation, and is
another good starting point.

[ref101]: http://markfrimston.co.uk/articles/30/quick-python-web-setup-for-apache
[ref102]: https://modwsgi.readthedocs.io/en/master/user-guides/quick-configuration-guide.html

## Configuring httpd

I'm going to just use `cgi-bin` directory, instead of creating a new
`wsgi-scripts` directory like all the documents suggest. Here are some
cuts from `/etc/httpd/conf/httpd.conf`.

```

