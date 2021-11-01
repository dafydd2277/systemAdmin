# Notes on ClamAV antivirus software.

## 2021-10-31

### Local Database Mirror

If you're running an enterprise,
[create a local mirror of the definition files][211031a]. That way,
you're reducing the amount of traffic leaving your firewall and moving
out in the world.


### Scripting the EICAR Test File

If you want to add the [EICAR][211031b] file to deliberately generate a
positive result from a virus scan, keep it as a [base64][211031c]
string, so the script you use to apply the test file doesn't itself be
flagged as a positive hit.

(According to the EICAR specification, compliant AV scanners should
only hit on the test file when the test string is the first 64 bytes
of the file and the file as a whole is not more than 128 bytes long.
So, this may be overkill when using a well designed scanner.)

```
df_testfile="/etc/virus_test.txt"
s_eicar64='WDVPIVAlQEFQWzRcUFpYNTQoUF4pN0NDKTd9JEVJQ0FSLVNUQU5EQVJELUFOVElWSVJVUy1URVNULUZJTEUhJEgrSCoK'

echo ${s_eicar64} | base64 -d - >${df_testfile}
```


[211031a]: https://docs.clamav.net/faq/faq-cvd.html#im-running-clamav-on-a-lot-of-clients-on-my-local-network-can-i-serve-the-cvd-files-from-a-local-server-so-that-each-client-doesnt-have-to-download-them-from-your-servers
[211031b]: https://en.wikipedia.org/wiki/EICAR_test_file

