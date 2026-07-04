# Docker daemon config

`daemon.json` is host-level Docker configuration (not a container). It:

- **Rotates container logs** so they can't silently fill your disk — a common homelab gotcha on low-storage machines.
- **Sets a private address pool** so Docker doesn't run out of internal subnets once you have many services.

To apply it on the host:

```sh
sudo cp daemon.json /etc/docker/daemon.json
sudo systemctl restart docker
```
