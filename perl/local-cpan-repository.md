# Creating a Local CPAN Repository

## Prerequisites

~~~~~bash
yum -y install \
  gcc \
  gmp \
  gmp-devel \
  openssl-devel \
  perl-CPAN \
  perl-CPANPLUS \
  perl-Env \
  perl-YAML

~~~~~


## Configure CPAN

The first time you run CPAN, it will try to establish a configuration.

~~~~~bash
cpan

~~~~~


Set the configuration like this.

- DO NOT "configure as much as possible automatically."


If you're installing as `root`, CPAN Config may complain,
falsely, that you don't have "write permission for Perl library
directories." Choose "manual."

You may take the suggested answers for all other entries except
the following:

- CPAN build and cache directory: /usr/local/cpan
- Store and re-use state information about districutions between
CPAN.pm sessions? yes
- Always commit changes to config variables to disk? yes
- Always try to check and verify signatures if a SIGNATURE file is in
the package and Module::Signature is installed? yes
- Do you want to halt on failure? yes
- Do you want to turn on colored output? yes
- Color for normal output? white on_black
- Color for warnings? bold red on_black
- If no urllist has been chosen yet, would you prefer CPAN.pm to
connect to the built-in default sites without asking? no

Results are written to `/usr/share/perl5/CPAN/Config.pm`. Settings
can be modified by executing "o conf" after starting CPAN. Execute that
now, to review your settings.

```bash
o conf

```

You can do `o conf <key> "<value>"` to change a setting, or `o conf
init` to run through the initialization questions again.

While still at the `cpan[#]>` prompt, update CPAN itself:

```bash
install Bundle::CPAN

install CPAN::Mini

quit

```


## Configure CPAN Mini and Download the Repository

```bash
mkdir --mode 2775 /var/www/html/cpan
chown root:wheel /var/www/html/cpan

cat <<EOMINI >/var/www/html/cpan/.minicpanrc
local: /var/www/html/cpan

EOMINI

```

Then, you can download the CPAN repository to have a local copy.

```bash
cd /var/www/html/cpan
time /usr/local/bin/minicpan \
  -l /var/www/html/cpan/ \
  --debug

```
