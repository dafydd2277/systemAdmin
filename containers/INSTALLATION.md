# Installing Kubernetes for Podman.

> NOTE: 2021-07-05 This is my current work in progress.

The [CentOS 8][] clone of [Docker][] is [Podman][]. I have not yet seen any
documentation on how to hook up [Kubernetes][] with Podman. But, Podman
uses `runc`. So, [K8s][] should work.

Oh, wait. Theres [this][ref101] on the [Red Hat sysadmin blog][ref102].
I'll have to see how that might work for me.


[CentOS 8]: https://centos.org/
[Docker]: https://www.docker.com/
[Podman]: http://podman.io/
[Kubernetes]: https://kubernetes.io/
[K8s]: https://www.easydeploy.io/blog/why-kubernetes-called-k8s/
[ref101]: https://www.redhat.com/sysadmin/podman-inside-kubernetes
[ref102]: https://www.redhat.com/sysadmin/


## Install Podman

```
dnf install podman podman-catatonit podman-plugins
```

Also consider `podman-compose` and `podman-docker` if you think you
would find them useful.


## Install Kubernetes

(I'll get to this after I've built the individual `bind` and `dhcpd`
containers that I'm going to pair in a K8s pod.)

