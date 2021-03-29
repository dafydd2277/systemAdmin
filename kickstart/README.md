# Kickstart Files for RHEL Installations

This is a set of kickstart files that present a hardened system on completion.

The CentOS 7 kickstart and associated files work through most of DISA STIGs for
the CentOS 7 family. The CentOS 8 kickstart might get there, if I get a client
that wants that. (My current client is just using Puppet, which works, too.)

## References

### Red Hat Documentation

- [Customizing a RHEL 7 installer][blog] - Works for CentOS 8, too. Just don't
stray from the path. The `mkisofs` command is unforgiving of experimentation.
- [Creating Kickstart Files for RHEL 8][rhel8ks]
- [RHEL 8 Burning an ISO to a USB Flash Drive][burniso]


[blog]: https://www.redhat.com/sysadmin/optimized-iso-image
[burniso]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-making-usb-media
[rhel8ks]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/creating-kickstart-files_installing-rhel-as-an-experienced-user


### Others

- [SCAP and Remediation][31]
- [WARNING: Processing an unresolved XCCDF document.][32]
- [The xccdf file for DISA STIG needs a sed modification][33] to work in OpenSCAP. See item 3 at the link.
- [The xccdf file also needs to become Centos, not RedHat][34].



[31]: http://myopensourcelife.com/2013/09/08/scap-and-remediation/
[32]: https://lists.fedorahosted.org/pipermail/scap-security-guide/2012-May/000573.html
[33]: http://open-scap.org/page/Documentation#How_to_Evaluate_Defense_Information_Systems_Agency_.28DISA.29_Security_Technical_Implementation_Guide_.28STIG.29_on_Red_Hat_Enterprise_Linux_5
[34]: https://www.redhat.com/archives/spacewalk-list/2014-November/msg00007.html
