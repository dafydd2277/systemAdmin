# Notes on sudo


## Logging sudo commands

https://unix.stackexchange.com/questions/108577/how-to-log-commands-within-a-sudo-su#109836


## Clearing old files from sudo-io

```
find /var/log/sudo-io –maxdepth 2 –mtime 7 –type f ! –name seq –delete 2>/dev/null
find /var/log/sudo-io –maxdepth 2 –mtime 7 –type d ! –name seq -delete 2>/dev/null
```
