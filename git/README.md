# Manipulating git

My collection of notes on customizing git.

## References
- Of course, start with https://git-scm.com/docs/ and http://git-scm.com/book/en/v2
- https://github.com/github/gitignore
- https://ochronus.com/git-tips-from-the-trenches/


## Git config customizations

```bash
# Set your information
git config --global user.name <name>
git config --global user.email <email>

# Push whatever branch you're on, provided the remote repository has a
# branch of the same name..
git config --global push.default matching

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

```


To see the configuration items you have set, try

```bash
git config --global --list

```

## Commit messages.

Yes, [a convention exists][git-commit]. The first line is what appears in the short logs. Keep that note specific and under about 50 characters. If you want to go into more detail, add a line of blank space and then start a paragraph on the third line of your git editor.

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

So, short one-line summary, skip a line, and go into more detail about what you're doing, if you need to. Finish by uncommenting the list of files being committed, so someone can review that in log entries as well.


[git-commit]: http://chris.beams.io/posts/git-commit/

