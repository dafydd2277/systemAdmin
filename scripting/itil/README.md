# ITIL, Sort of

<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->
Okay, no. This isn't really [ITIL][]. I had a client with several
subdomains with individual Puppet Servers that were disconnected for
security reasons. The disconnection meant they didn't have a really
good way to collect basic information on *all* of the servers to keep
in a *single* location. Solving that problem became an experiment in
using SQLite to keep the information and Python.

Since the Puppet API returns JSON, trying a fact gathering script in
Bash would largely have been a collection of Python one-liners. So,
just do it in Pythin, and learn Python as I go...

[ITIL]: https://en.wikipedia.org/wiki/ITIL

## 2020-12-14

Add the files.
