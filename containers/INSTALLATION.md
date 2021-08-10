# Installing Docker and Kubernetes

The [CentOS 8][] clone of [Docker][] is [Podman][]. Unfortunately,
Podman doesn't seem ready for prime time, yet. So, I deleted it and
[installed Docker][ref101]. 


[CentOS 8]: https://centos.org/
[Docker]: https://www.docker.com/
[Podman]: http://podman.io/
[Kubernetes]: https://kubernetes.io/
[ref101]: https://docs.docker.com/engine/install/centos/


## Install Docker

Based on the installation link, above, here are the commands I used to
remove Podman and install Docker.

```
dnf remove runc 'podman*'

rm -rf /var/lib/containers/

dnf install yum-utils

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf install docker-ce docker-ce-cli containerd.io
```


## Install Kubernetes

> 2021-08-10: I'll get to this after I've built the individual `dhcpd` and `bind`
containers that I'm going to pair in a K8s pod.

