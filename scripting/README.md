# BASH Scripting

## 2020-01-08

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
