# Containers

> NOTE: This are initial notes of my current work.


For containerization practice, I want to put my `dhcpd` and `bind`
services in a [Kubernetes][ref01] pod. I also have plans to create a
pod of `389-ds` and `krb5`, and a pod for my personal website. (Yes,
I've seen that meme sneering at the overkill of creating a K8s pod for
a personal website. The website isn't the point. The K8s practice is
the point.)

While my K8s "cluster" will only contain a single node, this is good
practice for larger scale applications.

Useful commands:

```
kubectl version

kubectl cluster-info
```

[ref01]: https://kubernetes.io/


## Security

Use complete paths to containers whenever possible. For example, use

```
docker run -dp 80:80 docker.io/docker/getting-started
```

instead of

```
docker run -dp 80:80 docker/getting-started
```

to make sure you get the container from `docker.io`, and not
(eg.) `registry.access.redhat.com` or `redhat.io`, or another registry
in your list that may have a container of the same name.


## References

- [Docker Compose Tutorial][ref91]
- [Kubernetes Tutorials][ref92]
- [Podman Tutorial][ref93]

[ref91]: https://docs.docker.com/compose/gettingstarted/
[ref92]: https://kubernetes.io/docs/tutorials/
[ref93]: https://www.redhat.com/sysadmin/container-networking-podman


## Ephemera

My test environment for containerization is CentOS 8 using `podman`.
While setting up my first containers, I hit [this problem][ref101] and
found [this solution][ref102]. Because I'm experimenting with a
firewall/forwarding system, I needed to [submit a modification][ref103].

[ref101]: https://github.com/containers/podman/issues/5352
[ref102]: https://github.com/greenpau/cni-plugins
[ref103]: https://github.com/greenpau/cni-plugins/pull/14

