# Bash hints and tricks.
 
Here are some hints and tricks I've discovered using [bash][].

For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[bash]: http://www.tldp.org/LDP/Bash-Beginners-Guide/html/index.html
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html

## Second Tuesday of the Month

You can't actually set [cron][] to run a process on the second Tuesday of the month. If you want to run a script at 02:00 on the second Tuesday of the month, you'd think this would work in cron:

```bash
00  02  08-14 * 2 /path/to/script.sh
```

That's the zeroeth minute of the second hour, in the range of day 8 to 14, on a Tuesday, because the second Tuesday of the month must fall between the 8th and the 14th. Unfortunately, aside from the hour and minute, cron timing is an `OR` function, not an `AND` function. So, this script will run on *every* Tuesday of the month, and *every day* from the 8th to the 14th, inclusive, at 02:00. So, what to do?

Well, you start by still using that cron entry, except for dropping the Tuesday. Then, you just need to put some additional date checking into the script itself.

```bash
i_daynum=$(date +%d)
s_dayword=$(date +%a)

if [[ ${i_daynum} > "07" ]] && [[ ${i_daynum} < "15" ]] && [ ${s_dayword} == 'Tue' ]
then
  # Execute your script
fi
```

([Why do I use dollar-parentheses instead of backticks in bash command expansion like `$(hostname -s)`?][faq082])

There's your `AND` inclusive date check. Alternately, you can use an `OR` arrangement to exit the script before execution.

```bash
i_daynum=$(date +%d)
s_dayword=$(date +%a)

if [[ ${i_daynum} < "07" ]] || ${i_daynum} > "14" ]] || [ ${s_dayword} != 'Tue' ]
then
  exit 1
fi

# Execute your script.
```

[faq082]: http://mywiki.wooledge.org/BashFAQ/082
[cron]: https://en.wikipedia.org/wiki/Cron


## Large parallel processing...

What if you want to spawn a bunch of processes to perform some sort of intensive test on your system. Here's an example that creates a large pseudo-random text file, and moves it around by way of gzip.

First, let's create the large text file.

```bash
d_source=/tmp/source
f_source=4Grandom.txt

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

```

The initial 4kB of text is random. It's then repeated 1024 * 1024 times for a 4GB pseudo-random text file.

Now, let's run that file through gzip/gunzip 8 times, to stress a processor. And, we'll include a `sleep` to space out the processes a little.

```bash
d_dest=/tmp/dest
i_sleep=1

mkdir -p ${d_dest}

for i in {1..8}
do
  time ( gzip --verbose --to-stdout ${d_source}/${f_source} 2>${d_dest}/gzip.stderr.${i} \
    |  gzip --decompress >${d_dest}/${f_source}.${i} ) \
    2> ${d_dest}/time.stderr.${i} &

  sleep ${i_sleep}
done

```

(Unfortunately, the number of iterations ( the "8" in `for i in {1..8}`) can't be a variable. I tried...)

This script generates 8 gzip/gunzip processes of a 4GB file for one or more processors to chew on. Compression ratios are recorded by the initial `gzip --verbose`'s STDERR, and the time taken for each process is captured from `time`'s STDERR. When I was using this for testing, I had [`dstat -vt`][dstat] running in another window to watch `usr` or `sys` percentages on the processor set.

[dstat]: http://dag.wiee.rs/home-made/dstat/


## Replacing multiple lines with awk.

Using sed to do modify a block of lines can get convoluted. It's much better at search and replace. When you have a block of text to add, awk is a much better choice. I don't have a good real-world example, yet. So, this might look a little weird, and is going in the direction of pseudo-bash. I know bash won't do substitutions on single-quoted lines. Just imagine variable substitions for the purposes of explaining how this works.

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

`RS` is `awk`'s internal end-of-line (EOL) variable. `$0` is the line matched by the initial regular expression. So, you can delete that line and substitute something else just by not using `$0`.

([Source](http://stackoverflow.com/questions/22497246/insert-multiple-lines-into-a-file-after-specified-pattern-using-shell-script))



