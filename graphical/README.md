# Notes on Graphical Displays

## 2024-07-02

I've found recently that `xauth -i add ...` now wants the entire line,
not just the key. So, the command now looks like

```bash
xauth -i add host050.int.example.com:11  MIT-MAGIC-COOKIE-1  a8404a54f1d05407726555d28cb4bf78
```


## 2022-06-23

### XDMCP

We'll start this with how to configure GDM to permit XDMCP by 
modifying `/etc/gdm/custom.conf` using [the example above][custom.conf]
and restarting GDM. This will allow any XDMCP client to connect. The
biggest advantage XDMCP has over VNC is that a VNC server requires a
customized start process and ongoing maintenance.

If you're still on RHEL 6, why? But, you can do `init 3` followed by
`init 5` to restart GDM. On modern versions, the command is
`systemctl restart gdm`.

[custom.conf]: ./custom.conf

### Xauth

If your method of getting Linux windows is to run an X Server on your
client system, that works well when you SSH directly to your target. If
you need to jump through an initial SSH hoop to reach your destination,
you need to pass along your $DISPLAY variable and your `xauth`
encryption code. Here's how to do that.

On the initial system, execute the command `xauth list` to get the
encryption key for your session. It's typically the last line in the
listing and is identified by `DISPLAY` value being the system you're
logged into. Here's an example:

```
host001/unix:10  MIT-MAGIC-COOKIE-1  dfdb4904525730c4d6d1d42fcb739570
host016/unix:10  MIT-MAGIC-COOKIE-1  419c98a5ecf70b0808f19efad54bd886
jump11.int.example.com:11  MIT-MAGIC-COOKIE-1  df73ac9eb6a58a699755704c9fc99397
host022/unix:10  MIT-MAGIC-COOKIE-1  b8adadba98824ae61e45b6c6c6f9ad9e
jump02.int.example.com:10  MIT-MAGIC-COOKIE-1  2d8a7692a6759d73e15e3690f9d479d0
host050.int.example.com:10  MIT-MAGIC-COOKIE-1  4d82e2cdc30cd95dbfa4e3472066263f
host050.int.example.com:11  MIT-MAGIC-COOKIE-1  a8404a54f1d05407726555d28cb4bf78
```

So, I'm logged into host050, but which display am I using? You could
execute `echo $DISPLAY` to get that information, but I have what I
think is a better way. Try executing `env | grep DISPLAY`, instead.

```
$ env | grep DISPLAY
DISPLAY=192.168.16.38:11.0
```

Now, you have the line you can copy and paste in to your destination
system following an `export` command.

So, from your jump host, SSH to your destination host. Then, set the
display value to reach back to, like this:

```
$ export DISPLAY=192.168.16.38:11.0
```

Then, now that we know we're working through display 11, copy just the
key portion (`a8404a54f1d05407726555d28cb4bf78`) of the final line from
`xauth list`, and add it in to the xauth table of your final
destination host by doing this:

```
$ xauth -i add a8404a54f1d05407726555d28cb4bf78
```

And that should allow X windows from your destination host to pass
back through the jump system and be rendered on your desktop.

