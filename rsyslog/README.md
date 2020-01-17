# Notes on rsyslog

## 2020-01-17

If you want to test an `rsyslog` configuration file, make sure it's in the right
location and has the right name. Then, try

```
rsyslogd -N1
```

The `rsyslog` daemon will scan the configuration files and let you know what it
finds. If you're not sure a file is being scanned, put a deliberate error in it.
