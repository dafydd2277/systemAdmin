# Manipulating git

My collection of notes on customizing git.

## References
- Of course, start with https://git-scm.com/docs/ and http://git-scm.com/book/en/v2
- https://github.com/github/gitignore
- https://ochronus.com/git-tips-from-the-trenches/


## Git config customizations

First, set yourself some variables.

```bash
userName="Given Middle Family"
userEmail="mailbox@mailhost.tld"
```


If you do those variables by hand, you can copy/paste the entirety of this next
block.

```bash
# Set your information
git config --global user.name "${userName}"
git config --global user.email "${userEmail}"

# Push whatever branch you're on, provided the remote repository has a
# branch of the same name..
git config --global push.default matching

# Set a global editor for commit messages
git config --global core.editor "/usr/bin/env vim"

# Helpful aliases
# For the first one, see https://github.com/crc8/GitVersionTree or
# http://stackoverflow.com/questions/1838873/visualizing-branch-topology-in-git
git config --global alias.gr \
  'log --graph --full-history --all --date=short --color --pretty=tformat:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%an)%x1b[0m"'
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.pl pull
git config --global alias.ps push
git config --global alias.st status
git config --global help.autocorrect 1
```


To see the configuration items you have set, try

```bash
git config --global --list
```


### GPG Signing

<!-- ----1----5----2----5----3----5----4----5----5----5----6----5----7----5 -->
In git 2.x, [you can sign your commits][20200123a] with a private GPG key. This
verifies that a commit came from you. To start, create a GPG key.

```bash
gpg2 --full-generate-key
```

Select `RSA and RSA` and a key size. These days, a key size of `2048` is
about as small as you should go. Set the other options as you need. Once
you have a key, tell git about it. First, list your keys.

```bash
gpg2 --list-keys
```


That will get you a result that looks something like this.

```bash
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
/home/${USER}/.gnupg/pubring.kbx
-------------------------------
pub   rsa3072 2024-07-08 [SC]
      3FCCA74FD238BF68F18DD301DCE0B75E816B3B42
uid           [ultimate] ${fullName} (${comment}) <${email}>
sub   rsa3072 2024-07-08 [E]
```


And then add that key signature to your git global config.

```bash
git config --global user.signingkey 3FCCA74FD238BF68F18DD301DCE0B75E816B3B42
```

Then, when you commit a change, the `-S` argument tells git to GPG sign
the key. **However**, `gpg` assumes the password entry will be a GUI
window. If you're working from a shell or an SSH session, you need to
use the second example to get a `curses` text-based password entry panel.

```bash
git commit -S

GPG_TTY=$(tty) git commit -S
```


If you want to submit your public key to https://www.github.com/ or
https://www.gitlab.com, you can use this command to print out an
ascii-armored version of your public key.

```bash
$ gpg2 --export -a 3FCCA74FD238BF68F18DD301DCE0B75E816B3B42
-----BEGIN PGP PUBLIC KEY BLOCK-----
##### KEY TEXT #####
-----END PGP PUBLIC KEY BLOCK-----
```


[20200123a]: https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work


## Commit messages.

Yes, [a convention exists][160303a]. The first line is what appears in the short logs. Keep that note specific and under about 50 characters. If you want to go into more detail, add a line of blank space and then start a paragraph on the third line of your git editor.

Additionally, I've taken to uncommenting the file modification notes that git preloads into the message editor. For example, here's what git loads into `vi` for me to modify:

```
# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
# On branch master
# Your branch is up-to-date with 'github/master'.
#
# Changes to be committed:
# modified:   README.md
#

```

I've started uncommenting everything under "Changes to be committed," so the list of new, modified, or deleted files actually gets added to the log entry for the change.

So, short one-line summary, skip a line, and go into more detail about what you're doing, if you need to. Finish by uncommenting the list of files being committed, so someone can review that in log entries as well. So, a good commit message would look like this.

```
Adds a one-line summary of no more than 50 characters

This commit expands on the idea of writing good commits, but including
the most critical summary in the top line, and then expanding on that
summary after a blank line.

# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
# On branch master
# Your branch is up-to-date with 'github/master'.
#
# Changes to be committed:
- modified:   README.md
#

```


[160303a]: http://chris.beams.io/posts/git-commit/

## Other Tricks

Set an upstream remote for the current branch

```bash
git branch -u <remote_name>/<branch_name>

```

Check out a clean copy of that remote branch

```bash
git branch -D <branch_name>

git checkout --track <remote_name>/<branch_name>

```

Get branch information from a remote, and delete any unmatched local branches.

```bash
git remote update <remote_name> --prune
```


Get a complete commit history of a file, in [diff][160303b]/[patch][160303c] format.

```bash
git log -p <filename>
```

To get diff/patch output for a particular commit, [try this][240707a].

```bash
git diff <file>

git diff <old commit> <new commit> <file>
```

[160303b]: https://linux.die.net/man/1/diff
[160303c]: https://linux.die.net/man/1/patch
[240707a]: https://riptutorial.com/git/example/4340/show-differences-for-a-specific-file-or-directory#example

