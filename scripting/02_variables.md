# BASH Variable Naming Conventions
2015-02-20

<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->
Several [articles][1], [blog posts][2], and [questions][3] discuss
variable naming conventions in `bash`. This is what I adopted. While I
haven't converted everything in [systemAdmin][] over to this format yet,
this is where I'm going. If I were to be prescriptive about a `bash`
naming convention, I would just say not to use unpunctuated, all caps
variable names. That will avoid most of the problems you see outlined on
the 'net.

I use lower case variables, with either underscores (_) for spaces or
modifedCamelCase, depending on what I feel like. As long as you're
consistent within a script, I don't think it matters. I uses prefixes on
my variable to give me a reminder of the type of information the
variable is carrying. However, this convention is not significant in
`bash`.

Finally, when using variables, I try hard to always use the `${s_name}
` format, rather than the simpler `$s_name`. As with most of this
particular doc, I just do it to [keep the habit][4] against the day I
really need to explicitly set out a variable name.

## Variable Prefixes
<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5- -->

- `d_name` - A complete directory structure, without a file name on the
end and without an ending slash (/) character. eg. `/etc/ssh`
- `df_name` - A fully pathed file name, eg. `/etc/ssh/sshd_config`. From
a variable assignment standpoint `df_name=${d_name}/${f_name}`.
- `e_name` - A fully pathed executable. If I'm going to parameterize
executables, I will always include the path. So, I don't see much point
in using a 2-character `de_name` prefix. But, you could do so.
- `f_name` - A simple file name. eg. `sshd_config`
- `fn_name` - No, functions aren't variables. However, I've found myself
expanding this naming conventions to include `fn_<name>` for functions
defined locally in a script, or `fn_<namespace>_<name>` for functions
that might be sourced from [some bash function library][20200127a].
(Yes, that's a bad example, since I didn't actually namespace those
functions.)
- `h_name` - A simple (`host`) or fully qualified
(`host.sub.domain.tld`) hostname, as needed. If distinguishing ever
becomes important, I might consider `q_name` for [FQDN][]s. If I'm feeling
over-the-top, I might do something like
`s_url=https://${h_host}.${s_domain}/${d_target}/${f_target}` to create a
full url for, say, `${e_wget} ${s_wget_opts} ${s_url}`...
- `i_name` - An integer. `Bash` is not strictly typed, so integers vs.
strings is relatively insignificant. This is just to help me remember what
the variable is for.
- `s_name` - Any string. The most common prefix.

I used to have a prefix for variables local to bash functions, to help minimize scope drift. Then, I learned that [variable scoping][20200127b] was possible in bash, and quit bothering.


[1]: http://wiki.bash-hackers.org/scripting/style
[2]: http://bashshell.net/shell-scripts/using-case-in-variables-in-bash-shell-scripts/
[3]: http://stackoverflow.com/questions/673055/correct-bash-and-shell-script-variable-capitalization
[systemAdmin]: https://github.com/dafydd2277/systemAdmin
[4]: http://stackoverflow.com/questions/8748831/bash-why-do-we-need-curly-braces-in-variables
[FQDN]: https://kb.iu.edu/d/aiuv
[20200127a]: https://github.com/dafydd2277/systemAdmin/blob/master/scripting/functions
[20200127b]: https://www.tldp.org/LDP/abs/html/localvar.html

