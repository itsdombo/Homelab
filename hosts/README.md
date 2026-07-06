# Hosts

This is the **placement** layer. `services/` says *how* each service is
defined; `hosts/` says *where* each service runs.

Each `hosts/<label>/` folder is one Docker host. Its `compose.yaml` uses
Compose's `include:` directive to pull in exactly the services that should run
on that host, nothing more.

```
hosts/
├── pve1/
│   ├── compose.yaml     # include: the services pve1 should run
│   └── .env.example     # copy to .env (gitignored) on the pve1 host
└── pve2/
    ├── compose.yaml     # include: the services pve2 should run
    └── .env.example     # copy to .env (gitignored) on the pve2 host
```

`pve1` is currently a placeholder (`include: []`) until its Docker host exists.
`pve2` is the live host today.

## Label vs hostname

`<label>` is a **logical name**, not the machine's hostname. `pve2` is an
unprivileged Proxmox LXC whose actual hostname is `media`, yet it still deploys
`hosts/pve2/` because its systemd unit sets `HOMELAB_HOST=pve2`. The deploy
never looks at `$(hostname)` in practice; the unit's `HOMELAB_HOST` decides
which dir this machine reconciles.

## The include gotcha (unique volume/network keys)

Everything a host `include:`s merges into one Compose project, so top-level
`volumes:`/`networks:` keys must be unique across all services on that host.
Two services both keyed `data` would collide. Name them per service, for
example `portainer_data` and `uptime_kuma_data`.

## Deploying by hand

```sh
docker compose --env-file hosts/pve2/.env -f hosts/pve2/compose.yaml up -d
```

Validate a host file without deploying anything (this resolves all includes and
variable interpolation):

```sh
docker compose --env-file hosts/pve2/.env -f hosts/pve2/compose.yaml config
```

## Deploying automatically

`tools/deploy.sh` on a timer does the pull-and-reconcile for whichever host it
runs on. See [`tools/systemd/README.md`](../tools/systemd/README.md).

## Moving a service between hosts

Delete its `include:` line from one host file, add it to the other, commit, and
push. The next reconcile on each host converges to the new placement.
