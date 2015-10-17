This is a set of kickstart files that present a hardened system on completion.

I'm working a little bit from [Red Hat Government's github repository][1], and a lot from the [Defense Information Systems Agency (DISA) Security Technical Implementation Guides (STIG)][2].

The CentOS 5 and 6 kickstart is functional. However, several items can't be fixed through a generic kickstart script, like having log and audit records transmitted to a remote server. Also, some of the tests appear to look for specific audit rule strings. They don't catch the combinations I set up using the recommendations from the [audit.rules(7)][3] man page, which suggests combining syscall elements into as few rules as practicable.

I'll do one for CentOS 7 as soon as the DISA STIG is released.

[1]: http://github.com/RedHatGov/
[2]: http://iase.disa.mil/stigs/Pages/index.aspx
[3]: http://linux.die.net/man/7/audit.rules

## Notes about the CentOS 5 kickstart.

- I did this one after the CentOS 6 kickstart, and it was much harder. The STIG descriptions are woefully inspecific. Several of the fixes had to be inserted from the [Aqueduct project][12], and even then some of the scripts won't result in passing tests.
- As with the CentOS 6 kickstart script, several of the audit rules meet the rules, but don't pass the tests as set by the OVAL test standards.
- In CentOS 5, `avahi-daemon` must be installed to satisfy dependencies. So, all we can do is turn it off in the `%post` script. In CentOS 6, `avahi-libs` got split into their own package. So, the main [avahi][11] package is added to the `%packages` list for explicit removal. Not having a package installed is better than having to remember to make sure its not running. 


## Notes about the CentOS 6 kickstart.

- While not specific to DISA STIG, the [FIPS 140-2 Standard][22] is written in to the `hardened` kickstart.
- As experimentation went on, I had to break pieces out. By the time I was done, I had these.
- - A FIPS-only kickstart, to figure out why it was crashing my host.
- - An audit-only kickstart, to figure out why that wasn't working.
- - An "expanded" kickstart, to add in stuff that's good for security but isn't specific to the DISA STIG or FIPS 140-2. My future work will go in here.
- - - This file also includes a change in philosophy, where configuration files are predefined, stored, and copied into place in the `%post` script. In an Enterprise environment, where you may have 3-10 different kickstart files, having common files simplifies management of all those files.
- - - Additionally, [spacewalk][13] is designed to work with "snippets" like this. So, I'll have my environment already half assembled when I get around to my spacewalk installation.

[11]: http://www.avahi.org
[12]: https://fedorahosted.org/aqueduct/
[12]: https://fedorahosted.org/spacewalk/


## References

### Red Hat Documentation

[Red Hat 5 Installation Guide - Kickstart Installations][21]

[Red Hat 6 Installation Guide - Kickstart Installations][22]

[Red Hat 6 Security Guide - Federal Information Processing Standard (FIPS)][23]


[21]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Installation_Guide/ch-kickstart2.html
[22]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Installation_Guide/ch-kickstart2.html
[23]: https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Security_Guide/sect-Security_Guide-Federal_Standards_And_Regulations-Federal_Information_Processing_Standard.html

### Others

[SCAP and Remediation][31]

[WARNING: Processing an unresolved XCCDF document.][32]

[The xccdf file for DISA STIG needs a sed modification][33] to work in OpenSCAP. See item 3 at the link.

[The xccdf file also needs to become Centos, not RedHat][34].



[31]: http://myopensourcelife.com/2013/09/08/scap-and-remediation/
[32]: https://lists.fedorahosted.org/pipermail/scap-security-guide/2012-May/000573.html
[33]: http://open-scap.org/page/Documentation#How_to_Evaluate_Defense_Information_Systems_Agency_.28DISA.29_Security_Technical_Implementation_Guide_.28STIG.29_on_Red_Hat_Enterprise_Linux_5
[34]: https://www.redhat.com/archives/spacewalk-list/2014-November/msg00007.html


