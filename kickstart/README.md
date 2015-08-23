This is a set of kickstart files that present a hardened system on completion.

I'm working a little bit from [Red Hat Government's github repository][1], and a lot from the [Defense Information Systems Agency (DISA) Security Technical Implementation Guides (STIG)][2].

The CentOS 6 kickstart is functional. However, several items can't be fixed through a generic kickstart script, like having log and audit records transmitted to a remote server. Also, some of the tests appear to look for specific audit rule strings. They don't catch the combinations I set up using the recommendations from the [audit.rules(7)][3] man page, which suggests combining syscall elements into as few rules as practicable.



I'll do one for CentOS 7 as soon as the DISA STIG is released.

[1]: http://github.com/RedHatGov/
[2]: http://iase.disa.mil/stigs/Pages/index.aspx
[3]: http://linux.die.net/man/7/audit.rules

## References

### Red Hat Documentation

[Red Hat 6 Installation Guide - Kickstart Installations][11]

[Red Hat 6 Security Guide - Federal Information Processing Standard (FIPS)][12]



[11]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Installation_Guide/ch-kickstart2.html
[12]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Security_Guide/sect-Security_Guide-Federal_Standards_And_Regulations-Federal_Information_Processing_Standard.html

### Others

[SCAP and Remediation][21]

[WARNING: Processing an unresolved XCCDF document.][22]

[The xccdf file for DISA STIG needs a sed modification][23] to work in OpenSCAP. See item 3 at the link.

[The xccdf file also needs to become Centos, not RedHat][24].



[21]: http://myopensourcelife.com/2013/09/08/scap-and-remediation/
[22]: https://lists.fedorahosted.org/pipermail/scap-security-guide/2012-May/000573.html
[23]: http://open-scap.org/page/Documentation#How_to_Evaluate_Defense_Information_Systems_Agency_.28DISA.29_Security_Technical_Implementation_Guide_.28STIG.29_on_Red_Hat_Enterprise_Linux_5
[24]: https://www.redhat.com/archives/spacewalk-list/2014-November/msg00007.html


