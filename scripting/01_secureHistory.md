# Setting up BASH in RHEL6 and clones.
 
As a systems administrator, I frequently will have to execute commands with embedded passwords in them. This can create a security vulnerability in my `~/.bash_history` file. The [authors of bash][bash] anticipated this problem, and added some environment variables to reduce this risk.

I'm writing this as an [GitHub-flavored Markdown][gmd] doc. You can secure your interactive bash shell by doing nothing more than copying and pasting every code block, in order. (Almost. You have some options to select.) Please review all steps first, and adjust to suit your environment.
 
For the most part, you may take blank lines in the code blocks as separators for selecting lines to copy and paste. The significant exception is when I'm using [bash heredoc][heredoc] to create or add to a file. Then, you need to copy all the way to the `EOT` at the start of a line.

[bash]: http://www.tldp.org/LDP/Bash-Beginners-Guide/html/index.html
[gmd]: https://help.github.com/articles/github-flavored-markdown
[heredoc]: http://www.tldp.org/LDP/abs/html/here-docs.html

## References

- http://aplawrence.com/Linux/bash_history.html
- http://blog.sanctum.geek.nz/better-bash-history/
- https://sickbits.net/bash-defensive-measures-shell-history-logging/
- http://wiki.bash-hackers.org/internals/shell_options
- http://www.techrepublic.com/article/linux-command-line-tips-history-and-histignore-in-bash/

## Modifications

These modifications can go anywhere in the bash [startup file set][startup], depending on your intentions. In my environments, this code block goes in `/etc/profile`, so all users are restricted.

```bash
shopt -s histappend
shopt -s histverify
shopt -s cmdhist
export HISTFILE=~/.bash_history_$(hostname -s)
export HISTCONTROL=ignoreboth
export HISTIGNORE=""
export HISTSIZE=500
export HISTFILESIZE=10000
export HISTTIMEFORMAT='%F %T $'

readonly HISTFILE HISTCONTROL HISTIGNORE HISTSIZE HISTFILESIZE HISTTIMEFORMAT
```

([Why do I use dollar-parentheses instead of backticks in bash command expansion like `$(hostname -s)`?][faq082])

The important line is `export HISTCONTROL=ignoreboth`. This means the bash history store will not record any repeated commands (`ignoredups`) and it will not record any command that starts with a space (`ignorespace`). So, any password variable assignment (eg. `PASSPHRASE` or  `ADMIN_PASSWORD`) will start with a space character, to avoid having the password recorded in your .bash_history.

Here's a summary of the settings:
- histappend tells bash to write the command to the history file immediately.
- histverify tells bash to expand out an inferred command at the prompt, instead of immediately executing it. Then, you press `ENTER` a second time after verifying the expansion is what you want.
- cmdhist tries to save a multi-line command into a single history entry. This simplifies editing of the command on subsequent attempts to execute it.
- HISTFILE sets the destination for the history. Separating this histories of multiple hosts reduces the risk of an inappropriate command being run, and improves forensic investigation. Another option might be `HISTFILE=/var/log/bash_history/$(id -un)` to keep the history files on the host.
- HISTCONTROL is noted above.
- HISTIGNORE tells bash which commands to not include in the history file. Setting this to the empty string ensures all commands are saved, except those affected by HISTCONTROL.
- HISTSIZE is the number of recent entries kept in local memory.
- HISTFILESIZE is the number of recent entries kept in the history file.
- HISTTIMEFORMAT sets a timestamp for each entry in the file. This timestamp is repeated by the history command. This is handy for tracking commands after the fact and for forensics.

Finally, the [`readonly`][readonly] command prevents individual users from modifying these entries, provided you place the code block in /etc/profile.

[startup]: http://www.linuxfromscratch.org/blfs/view/6.3/postlfs/profile.html
[faq082]: http://mywiki.wooledge.org/BashFAQ/082
[readonly]: http://ss64.com/bash/readonly.html

## Another great tool

This one isn't so much a security issue as a really cool tool for bash. If you create a file in your `${HOME}` called `.inputrc` and include the following text, you can search through your bash history with the up and down arrow, filtered by whatever starting text you enter. This hint comes from <https://coderwall.com/p/oqtj8w>.

```bash
cat <<EOT >>~/.inputrc
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOT
```

Another trick is to add the line `set -o vi` in one of your personal bash startup files (`.bashrc` would be better than `.bash_profile`, but either usually works.) With this set, pressing Escape at a command prompt allows you to use vi commands to search your history and modify commands for new execution. I'm not as fond of `set -o vi`, but I know many people who swear by it.


