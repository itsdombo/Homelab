# Hosts

This is the **placement** layer. `services/` says *how* each service is
defined; `hosts/` says *where* each service runs.

Each `hosts/<name>/` folder is one Docker host. Its `compose.yaml` uses
Compose's `include:` directive to pull in exactly the services that should
run on that host — nothing more.

```
hosts/
├── pve1/
│   ├── compose.yaml     # include: the services pve1 should run
│   └── .env.example     # copy to .env (gitignored) on the pve1 host
└── pve2/
    ├── compose.yaml     # include: the services pve2 should run
    └── .env.example     # copy to .env (gitignored) on the pve2 host
```

`<name>` is a **logical label**, not necessarily the machine's hostname.
Each host's deploy job sets `HOMELAB_HOST=<name>` (in the systemd unit), so
the pve2 Docker LXC — whose hostname might be `media` — still deploys
`hosts/pve2/` because its unit says `HOMELAB_HOST=pve2`.

## Deploying by hand

```sh
docker compose --env-file hosts/pve2/.env -f hosts/pve2/compose.yaml up -d
```

Validate a host file without deploying anything (resolves all includes and
variable interpolation):

```sh
docker compose --env-file hosts/pve2/.env -f hosts/pve2/compose.yaml config
```

## Deploying automatically

`tools/deploy.sh` run on a timer does the pull-and-reconcile for whichever
host it's on. See `tools/systemd/`.

## Moving a service between hosts

Delete its `include:` line from one host file, add it to the other, commit,
push. The next reconcile on each host converges to the new placement.
