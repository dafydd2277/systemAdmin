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
# For the first one, see https://github.com/crc8/GitVersionTree.
git config --global alias.gr \
  'log --graph --full-history --all --color --pretty=tformat:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%an)%x1b[0m"'
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.pl pull
git config --global alias.ps push
```

