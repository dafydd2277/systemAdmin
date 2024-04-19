# Notes on the Linux Kernel

## Troubleshooting

If a process is behaving badly (eg. entering
[process state D][240419a] and no leaving), the [`/proc`][240419b]
pseudo-filesystem has tools to help start troubleshooting. The most
interesting is `/proc/$pid/stack`.

```bash
[ user@sandbox ~ ] $ sleep 3600 &
[1] 359297

[ user@sandbox ~ ] $ ps a \
>  | egrep '(STAT|sleep)' \
>  | grep -v grep
    PID TTY      STAT   TIME COMMAND
 359297 pts/1    S      0:00 sleep 3600
```

So, my sleep process is in "Interruptable Sleep." You can also find
the state by doing this:

```bash
[ user@sandbox ~ ] $ grep 'State' /proc/359297/status
State:  S (sleeping)
```

Now, what does the processes instruction look like while in this state?
Well, you can find that out from the `/proc` pseudo-filesystem as well.

```bash
[ user@sandbox ~ ] $ sudo cat /proc/359297/stack
[<0>] hrtimer_nanosleep+0x89/0x120
[<0>] __x64_sys_nanosleep+0x96/0xd0
[<0>] do_syscall_64+0x5b/0x1b0
[<0>] entry_SYSCALL_64_after_hwframe+0x61/0xc6
```

The most recent call is at the top of the stack, and traveling down the
stack goes "back in time," with respect to what the process is doing.
So, what is `hrtimer_nanosleep`? That's where we go look at
https://elixir.bootlin.com/linux/latest/source. Head to that page and
search "All symbols" for `hrtimer_nanosleep`. It's defined as a
function [here][240419c]. You can do similar searches for
[`__x64_sys_nanosleep`][240419d], too. Or wait! No, you can't! Instead,
you get "identifier not used." So, back up another and see what you get
for [`do_syscall`][240419e]. That one does return possible matches, but
they all seem architecture specific? Does `sleep` have separate source
code?

[It does][240419f]! [Let's go look][240419g]. Sadly in this case, it
doesn't really tell us anything useful. However, in a similar case at
`$DAYJOB` recently, we learned that a blocked NFS write call was
blocked becuase we assumed the NFS connection was
[`async`hronous][240419h], as is the default, was actually
`sync`hronous. So, the process was in Uninterruptable Sleep (D) and
was blocked waiting for the NFS server to confirm a series of writes.
That investigation continues...

[240419a]: https://www.baeldung.com/linux/process-states
[240419b]: https://docs.kernel.org/filesystems/proc.html
[240419c]: https://elixir.bootlin.com/linux/latest/source/kernel/time/hrtimer.c#L2087
[240419d]: https://elixir.bootlin.com/linux/latest/A/ident/__x64_sys_nanosleep
[240419e]: https://elixir.bootlin.com/linux/latest/A/ident/do_syscall
[240419f]: https://duckduckgo.com/?t=h_&q=linux+sleep+source+code&ia=web
[240419g]: https://github.com/coreutils/coreutils/blob/master/src/sleep.c
[240419h]: https://linux.die.net/man/5/nfs
