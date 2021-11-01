# Security

## 2021-10-31

### Security Notes as Files

Many of the security hints I've collected made more sense as examples
of the relevant files. So, have a look at the [sssd.conf][211031a] and
the sample [sysctl.d][211031b] files for hints on enhancing RHEL
security.


### SSH via Smartcard or Token

Once console/desktop access has been secured through PKI via a
Smartcard or USB token, that portable PKI certificate can then be used
to [derive an SSH secret/public key pair][211031c], allowing that
desktop to be used as an SSH client without having the users SSH secret
key in a file that can be exfiltrated.

Note that these instructions are for allowing a RHEL desktop system
to act as secure SSH client. To the best of my knowledge, the only
equivalent functionality for Windows desktop system is
[PuTTY-CAC][211031d], which is not commercially supported.

[211031a]: https://github.com/dafydd2277/systemAdmin/blob/main/security/etc/sssd.conf
[211031b]: https://github.com/dafydd2277/systemAdmin/tree/main/security/etc/sysctl.d
[211031c]: https://access.redhat.com/articles/1523343
[211031d]: https://github.com/NoMoreFood/putty-cac

