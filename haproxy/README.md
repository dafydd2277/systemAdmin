# Notes on haproxy.

## 2020-01-17

Here are a sample `haproxy.cfg` file and a corresponding `rsyslog.conf`
file that creates a local (`127.0.0.1`) listening socket for `haproxy`
to send logs to. The corresponding `/etc/logrotate.d/haproxy.conf` file
is left as a exercise for the reader.
