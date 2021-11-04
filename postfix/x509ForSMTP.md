# X.509 Certificate Service Extension for SMTP Servers

## TODO

- What are the X.509 OIDs for S/MIME functionality? RFC 4262 says an
X.509 certificate may specify S/MIME encryption as a capability.


## Introduction

Let's give SMTP Servers access to a repository of X.509 certificates
that identify email recipients managed by that server. The server
may provide the certificate to an email client, allowing the client
to encrypt the text of the email prior to sending.

With respect to Section 2.2.1 of [RFC 5321][rfc5321], I believe the
advantages of providing this additional functionality to a conversation
that the SMTP Client and Server are already having outweigh the
disadvantages of having to identify and interact with a different
certificate service on a different socket.


## Background

[RFC 3207][rfc3207] gives SMTP clients and servers STARTTLS
capability. Standards for email encryption exist ([RFC 3156][rfc3156],
[RFC 8550][rfc8550]), but the functionality provided by those
standards is not in widespread use.

As a result, email messages typically are not encrypted at rest. Once
a message is in a recipient's mailbox, that message is readable by
anyone who acquires access, licit or illicit.


## Proposal

### SMTP Servers / Mail Transport Agents

I can think of two options for SMTP Servers. Either serve the
certificates directly, or serve URLs by which an SMTP Client can
download the certificate.

In the first case, provide SMTP Servers access to a repository of X.509
PKI certificates for the email addresses managed by that Server. This
repository access MAY be internal to the server (eg. a directory on a
filesystem or an internally managed database), or MAY be a reference to
an externally managed repository like LDAP. Provide SMTP Servers with
the ability to transmit those certificates to SMTP Clients on request.
Solutions MAY provide SMTP Servers with a method to test certificates
against a CRL. Certificates on the CRL MUST NOT be transmitted to SMTP
Clients.

In the second case, provide SMTP Servers with a URL that can be sent
as a reply to a query from an SMTP Client.


### SMTP Clients / Mail User Agents

Provide Mail User Agents with the ability to generate self-signed
certificates and/or certificate signing requests. Mail User Agents MUST
have an option to disable this functionality, for those cases where an
external method of certificate creation exists. Mail User Agents having
this functionality SHOULD recommend that the password to the private
key be different than the password to access the POP/IMAP Server.

Provide Mail User Agents with the ability to encrypt messages by
querying the destination SMTP Server for an appropriate certificate.

Provide Mail User Agents with the ability to sign outgoing messages or
decrypt incoming messages using the user's PKI Private Key. The MUA's
access to the key MAY be a reference to a key kept elsewhere (eg. a
smart card).


## Requests and Submissions

Certificates provided to an SMTP Server for message encryption
MUST have a valid email address, as described in Section 3 of
[RFC 8550][rfc8550]. That email address MUST be for a domain managed
by the SMTP Server.


The SMTP Server MUST NOT provide certficates for non-local (CHANGEME
wording?) domains. SMTP Servers MUST NOT pass requests on to final
destinations, but MAY keep a repository of certificates for those
destinations. This is to say that certificates MUST NOT be "relayed,"
but a "gateway" SMTP Server may provide certificates for the domains
beyond it.


### CERT

Syntax: `CERT <forward-path>`

The SMTP Client is requesting the individual user certificate
configured for encrypting email destined for `forward-path`. If a
certificate belonging to `forward-path` is available, the SMTP Server
MUST reply with the contents of the certificate, followed by `250 OK`.

After the individual identification cert has been retrieved and the
message encrypted, the message is then sent to the server consistent
with [RFC 8550][rfc8550].

If the SMTP Server does not have a certificate for the requested
`forward-path`, it MUST reply with "550 Certificate Not Found".

```
S: 220 receiver.com SMTP Service Ready
C: EHLO sender.com
S: 250-receiver.com greets sender.com
S: 250-8BITMIME
S: 250-SIZE
S: 250-DSN
S: 250-CERT
S: 250-CERS
S: 250 HELP
C: CERT jsmith@receiver.com
S: 250------BEGIN TRUSTED CERTIFICATE-----
S: 250-Contents
S: 250-of
S: 250-Certificate
S: 250------END TRUSTED CERTIFICATE-----
S: 250 OK
C: MAIL FROM:<reverse-path>
S: 250 OK
C: RCPT <forward-path>
S: 250 OK
C: DATA

(and so on)

.
S: OK
```


### CERS

Syntax: `CERS <forward-path>`

The SMTP Client is requesting the individual user certificate
configured for encrypting email destined for `forward-path` is
available, along with the certificates used in that certificate's
signing chain. The SMTP Server MUST reply with the contents of the
individual user certificate, followed by the contents of any signing
certificates used to sign that certificate, followed by `250 OK`. The
SMTP Server SHOULD NOT perform any queries towards completing the
certificate signing chain. The SMTP Server responds with what it has,
and the SMTP Client, or auxilliary functionality, can discover the
remainder of the chain.

After the individual identification certificate has been retrieved and
the message encrypted, the message is then sent to the server
consistent with [RFC 8550][rfc8550].

If the SMTP Server does not have a certificate for the requested
`forward-path`, it MUST reply with "550 Certificate Not Found".

```
S: 220 receiver.com SMTP Service Ready
C: EHLO sender.com
S: 250-receiver.com greets sender.com
S: 250-8BITMIME
S: 250-SIZE
S: 250-DSN
S: 250-CERT
S: 250-CERS
S: 250 HELP
C: CERT jsmith@receiver.com
S: 250------BEGIN TRUSTED CERTIFICATE-----
S: 250-Contents
S: 250-of
S: 250-Certificate
S: 250------END TRUSTED CERTIFICATE-----
S: 250------BEGIN TRUSTED CERTIFICATE-----
S: 250-Contents
S: 250-of
S: 250-Certificate
S: 250------END TRUSTED CERTIFICATE-----
S: 250 OK
C: MAIL FROM:<reverse-path>
S: 250 OK
C: RCPT <forward-path>
S: 250 OK
C: DATA

(and so on)
.
S: OK
```


### CERC

Syntax: `CERC <forward-path>`

This command allows an SMTP Client (typically a Mail User Agent) to
submit an individual user certificate. Server MAY reject for incorrect
or inappropriate domain specified by the certificte. SMTP servers MAY
require a certificate be valid for email encryption consistent with
[RFC 4262][rfc4262]. In either case, use "550 Invalid Certificate". The
SMTP Server MUST notify the postmaster on each submission, and MUST
provide a mechanism for the server administrator to accept or reject
client-submitted certificates.

SMTP Servers MAY reject all certificates submitted in this way. In this
case, SMTP Servers MUST respond with "550 Service Unavailable".

```
S: 220 receiver.com SMTP Service Ready
C: EHLO sender.com
S: 250-receiver.com greets sender.com
S: 250-8BITMIME
S: 250-SIZE
S: 250-DSN
S: 250-CERT
S: 250-CERS
S: 250-CERC
S: 250-HELP
C: CERC jsmith@receiver.com
S: 250 OK
C: DATA
C: -----BEGIN TRUSTED CERTIFICATE-----
C: Contents
C: of
C: Certificate
C: -----END TRUSTED CERTIFICATE-----
C: .
S: 250 OK
```


## Questions and Answers

Q: Why make an SMTP server do something that is clearly not SMTP?

>A: The objective is to make encrypted email the default option. All
email text and attachments are encrypted at rest, with minimal ongoing
user intervention. We can all think of cases of email exfiltration
that has hurt businesses and governments. The problem with GPG and
similar solutions is that adoption is not nearly extensive enough to
be useful. Public certificates need to be everywhere and absurdly easy
to get. The ubiquity of SMTP servers and the direct link between email
encryption and email transmission make this extended functionality a
perfect match. The closest alternative I can think of is where someone
proposes, and gets approved, a DNS record identifier for an X.509
certificate server analagous to the existing `MX` record.


Q: Why not GPG?

>A: This could be set up for GPG, as well. My take is that X.509 is
almost as ubiquitous as SMTP is at this point. Every TLS connection
uses it, and it's already used to identify individuals, frequently
through the use of smart cards and embedded X.509 identity
certificates.

>Also, one of GPG's biggest weak spots is the difficulty of
establishing a chain of trust. That usually requires physical
connections and "key signing parties." X.509 solves this problem with
its certificate signing requests and identity verification.


Q: What X.509 Extensions?

>A: Looking at Sections 4.2.1.3 and 4.2.1.12 of [RFC 5280][rfc5280],
`digitalSignature`, `nonRepudiation`, and `emailProtection` seem
appropriate. However, I'm sure someone smarter than I am will have a
better answer.


## References

- Bradner, S., "Key words for use in RFCs to Indicate Requirement
Levels", [BCP 14][bcp14], [RFC 2119][rfc2119], DOI 10.17487/RFC2119,
March 1997, <[https://www.rfc-editor.org/info/rfc2119][rfc2119]>. (See
also: [RFC 8174][rfc8174])

- Klensin, J., "Simple Mail Transfer Protocol", [RFC 5321][rfc5321],
DOI 10.17487/RFC5321, October 2008,
<[https://www.rfc-editor.org/info/rfc5321][rfc5321]>

- IANA, "Simple Mail Transfer Protocol (SMTP) Enhanced Status Codes
Registry",
<[http://www.iana.org/assignments/smtp-enhanced-status-codes][iana]>.

- Vaudreuil, G., "Enhanced Mail System Status Codes", [RFC
3463][rfc3463], DOI 10.17487/RFC3463, January 2003,
<[https://www.rfc-editor.org/info/rfc3463][rfc3463]>.

- Schaad, J., et al., "Secure/Multipurpose Internet Mail Extensions
(S/MIME) Version 4.0 Message Specification", [RFC 8550][rfc8550], DOI
10.17487/RFC8550, April 2019,
<[https://www.rfc-editor.org/info/rfc8550][rfc8550]>.

- Hoffman, P., "SMTP Service Extension for Secure SMTP over Transport
Layer Security", [RFC 3207][rfc3207], DOI 10.17487/RFC3207, February
2002, <[https://www.rfc-editor.org/info/rfc3207][rfc3207]>.

- Elkins, M., et al., "MIME Security with OpenPGP",
[RFC 3156][rfc3156], DOI 10.17487/RFC3156, August 2001,
<[https://www.rfc-editor.org/info/rfc3156][rfc3156]>.

- Cooper, D., et al., "Internet X.509 Public Key Infrastructure
Certificate and Certificate Revocation List (CRL) Profile", [RFC
5280][rfc5280], DOI 10.17487/RFC5280, May 2008,
<[https://www.rfc-editor.org/info/rfc5280][rfc5280]>.

- Melnikov, A., et al., "Internationalized Email Addresses in X.509
Certificates", [RFC 8398][rfc8398], DOI10.17487/RFC8398, May 2018,
<[https://www.rfc-editor.org/info/rfc8398][rfc8398]>.

- Santesson, S., "X.509 Certificate Extension for Secure/
Multipurpose Internet Mail Extensions (S/MIME) Capabilities",
[RFC 4262][rfc4262], DOI 10.17487/RFC4262, December 2005,
<[https://www.rfc-editor.org/info/rfc4262][rfc4262]>.


[bcp14]: https://tools.ietf.org/html/bcp14
[rfc2119]: https://www.rfc-editor.org/info/rfc2119
[rfc8174]: https://www.rfc-editor.org/info/rfc8174
[rfc5321]: https://www.rfc-editor.org/info/rfc5321
[iana]: http://www.iana.org/assignments/smtp-enhanced-status-codes
[rfc3463]: https://www.rfc-editor.org/info/rfc3463
[rfc8550]: https://www.rfc-editor.org/info/rfc8550
[rfc8398]: https://www.rfc-editor.org/info/rfc8398
[rfc3207]: https://www.rfc-editor.org/info/rfc3207
[rfc3156]: https://www.rfc-editor.org/info/rfc3156
[rfc5280]: https://www.rfc-editor.org/info/rfc5280
[rfc8398]: https://www.rfc-editor.org/info/rfc8398
[rfc4262]: https://www.rfc-editor.org/info/rfc4262

