# BASH Scripting

## 2020-08-25

I've added a Python script to pick out and manipulate XML record entries from
an Apple Health data download, to summarize information I'm interested in.


## 2020-07-22

"[Real SysAdmins Don't Sudo][nosudo]"

David Both raises some good philosophical points about how running all
privileged commands through `sudo` is a mis-use of the command. I largely agree
with him. I want to note an important caveat and use case, though. In strongly
audited environments, locking the root account and requiring `sudo` for all
privileged commands, or even `sudo su - root`, creates an audit trail of the
operations SysAdmins are running. That audit trail can then be immediately
logged to a location controlled by other SysAdmins, and remains available for
forensic analysis of a system whose breakage may have been malicious.

Remember, the most common sort of attack on an information system is an
insider attack.

[nosudo]: http://www.both.org/?p=960


## 2020-01-27

Let's move the [BASH][] Hints and Tricks page into the README, and stick it all
up front.

[BASH]: http://www.tldp.org/LDP/Bash-Beginners-Guide/html/index.html

### Second Tuesday of the Month
<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->

You can't actually set [cron][] to run a process on the second Tuesday
of the month. If you want to run a script at 02:00 on the second Tuesday
of the month, you'd think this would work in cron:

```bash
00  02  08-14 * 2 /path/to/script.sh
```

That's the zeroeth minute of the second hour, in the range of days 8 to
14, any day of the month, and on a Tuesday because the second Tuesday of
the month must fall between the 8th and the 14th. Unfortunately, aside
from the hour and minute, cron timing is an `OR` function, not an `AND`
function. So, this cron entry will run on *every* Tuesday of the month,
and *every day* from the 8th to the 14th, inclusive, at 02:00. So, what
to do?

Well, you can still start with that cron entry. Just drop the Tuesday:
`00 02 08-14 * *`. Then, you just need to put some additional date
checking into the script itself.

```bash
i_daynum=$( date +%-d )
s_dayword=$( date +%a )

if [[ "${i_daynum}" -ge "8" ]] \
  && [[ "${i_daynum}" -le "14" ]] \
  && [ "${s_dayword}" == "Tue" ]
then
  # Execute your script
fi

```
<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->

( [Why do I use dollar-parentheses instead of backticks][faq082] in bash command
expansion like `$( hostname -s )`? )

There's your `AND` inclusive date check. The down side is that the
remainder of the script will be indented, by convention. I'll just call
that problem an incentive to turn most of your code into functions
within the script, and your main code block can just be indented calls
to those functions.

Or, alternately, you can use an `OR` arrangement to exit the script before execution.

```bash
i_daynum=$( date +%-d )
s_dayword=$( date +%a )

if [[ "${i_daynum}" -lt "8" ]] \
  || [[ "${i_daynum}" -gt "14" ]] \
  || [ "${s_dayword}" != "Tue" ]
then
  exit 1
fi

# Execute your script.

```

[faq082]: http://mywiki.wooledge.org/BashFAQ/082
[cron]: https://en.wikipedia.org/wiki/Cron


### Large parallel processing...
<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->

What if you want to spawn a bunch of processes to perform some sort of
intensive test on your system. Here's an example that creates a large
pseudo-random text file, and moves it around by way of gzip.

First, let's create the large text file.

```bash
d_source=/tmp/source
f_source=4GBOfRandom.asc

mkdir -p ${d_source}

tr -dc 'a-zA-Z0-9!@#$%^*_=+' </dev/urandom \
  | head -c 4096 >${d_source}/4kRandomSeed.txt

for i in {1..1024}
do
  cat ${d_source}/4kRandomSeed.txt >> ${d_source}/4Mrandom.txt
done

for i in {1..1024}
do
  cat ${d_source}/4Mrandom.txt >> ${d_source}/${f_source}
done

rm -f ${d_source}/4kRandomSeed.txt ${d_source}/4Mrandom.txt
```

The initial 4kB of text is random. It's then repeated 1024 * 1024 times
for a 4GB pseudo-random text file. If you want genuinely random
[ASCII][], you can do

```
base64 -i /dev/urandom \
  head -c 4294967296 > 4GBOfRandom.asc

```

and go have lunch while it runs. (Or stick around and enjoy watching
`top` freak out. I won't judge.)

<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->

Now, let's run that file through gzip/gunzip 8 times, to stress a
processor. And, we'll include a `sleep` to space out the processes a
little.

```bash
d_dest=/tmp/dest
i_sleep=1

mkdir -p ${d_dest}

for i in {1..8}
do
  time ( gzip \
           --verbose \
           --to-stdout ${d_source}/${f_source} \
           2>${d_dest}/gzip.stderr.${i} \
         | gzip \
           --decompress \
           >${d_dest}/${f_source}.${i} ) \
    2> ${d_dest}/time.stderr.${i} \
    &

  sleep ${i_sleep}
done

```

(Unfortunately, the number of iterations ( the "8" in `for i in {1..8}`)
can't be a variable. I tried...)

This script generates 8 `gzip`/`gunzip` processes of a 4GB file for one
or more processors to chew on. Compression ratios are recorded by the
initial `gzip --verbose`'s STDERR, and the time taken for each process
is captured from `time`'s STDERR. When I was using this for testing, I
had [`dstat -tclypms`][dstat] running in another window to watch `usr` or
`sys` percentages on the processor set.

[ASCII]: https://en.wikipedia.org/wiki/ASCII/
[dstat]: http://dag.wiee.rs/home-made/dstat/


### Replacing multiple lines with awk.
<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->

Using sed to do modify a block of lines can get convoluted. It's much
better at search and replace. When you have a block of text to add, awk
is a much better choice. I don't have a good real-world example, yet.
So, this might look a little weird, and is going in the direction of
pseudo-bash. I know bash won't do substitutions on single-quoted lines.
Just imagine variable substitions for the purposes of explaining how
this works.

```bash
f_input=<file to search in>

s_search=<string to search for>
s_line_1=<new line 1>
s_line_2=<new line 2>
s_line_3=<new line 3>

awk '/${s_search}/{print $0 RS "${s_line_1}" RS "${s_line_2}" RS "${s_line_3}";next}1' \
  ${f_input} > /tmp/file \
  && mv /tmp/file ${f_input}

```

`RS` is `awk`'s internal end-of-line (EOL) variable. `$0` is the line
matched by the initial regular expression. So, you can delete that line
and substitute something else just by dropping the `$0`.

([Source](http://stackoverflow.com/questions/22497246/insert-multiple-lines-into-a-file-after-specified-pattern-using-shell-script))


## 2020-01-08
<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->

Here are the [Bash][20200108a] scripts and ideas that I've collected
over the years. (The scripts have been here a while, but this README is
new...)

Here are a couple links I've found recently that are worth sharing.

- [Bash "Strict Mode"][20200108b] - My scripts don't have this in
place, yet. New scripts will include this and my older scripts will get
updated if I have to revise them out in the world.

```
set -euo pipefail
IFS=$'\n\t '

```

- [Bash EXIT traps][20200108c] - Here's something else I'll add to new
scripts to ensure any temporary files get deleted if the script exits
for any reason.


[20200108a]: http://tldp.org/LDP/Bash-Beginners-Guide/html/index.html
[20200108b]: http://redsymbol.net/articles/unofficial-bash-strict-mode/
[20200108c]: http://redsymbol.net/articles/bash-exit-traps/
