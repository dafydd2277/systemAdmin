# General Notes on Postfix

## 2015-08-18 - Adding custom headers to outgoing emails.

Add `X-Clacks-Overhead: GNU Terry Pratchett` to every outgoing email. Inspired by http://www.gnuterrypratchett.com/#postfix


```bash
cp /etc/postfix/main.cf /etc/postfix/main.cf.orig

patch /etc/postfix/main.cf
546a547,549
> # <user> <date>
> header_checks = regexp:/etc/postfix/header_checks
> 


cp /etc/postfix/header_checks /etc/postfix/header_checks.orig

patch /etc/postfix/header_checks
419a420,426
> 
> # <user> <date>
> # http://www.gnuterrypratchett.com/
> # http://unix.stackexchange.com/questions/44123/add-header-to-outgoing-email-with-postfix
> /^X-Clacks-Overhead:/ IGNORE
> /^Content-Transfer-Encoding:/i PREPEND X-Clacks-Overhead: GNU Terry Pratchett
> 

```

