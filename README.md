# Homelab

This repository is the source of truth for my homelab. Each self-hosted
service is defined as a [Docker Compose](https://docs.docker.com/compose/)
file, so the repo *is* the setup — to rebuild everything on a new machine I
just install Docker, clone this repo, and run the services.

Unlike a hypervisor-based setup, everything here runs as containers directly
on a single Linux host. No VMs, minimal overhead.

## Layout

```
Homelab/
├── services/            # one folder per self-hosted service
│   ├── .env.example     # template for secrets/config (copy to .env)
│   ├── portainer/       # container management web UI
│   └── uptime-kuma/     # uptime/status monitoring
└── tools/               # host-level config that isn't a container
    └── docker/          # Docker daemon config
```

## Getting started

See [`services/README.md`](./services/README.md) for the commands to bring
services up, down, and up to date.

## Adding a new service

1. Create a new folder under `services/` named after the service.
2. Add a `compose.yaml` file describing it.
3. Add any new variables it needs to `services/.env.example`.
4. Commit and push. On the host: `git pull`, then start the service.
