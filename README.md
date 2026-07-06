# Homelab

This repository is the source of truth for my homelab. Every self-hosted
service is a [Docker Compose](https://docs.docker.com/compose/) file, so the
repo *is* the setup. A host is rebuilt by installing Docker, cloning this repo,
and letting the deploy timer reconcile it.

Everything runs as Docker containers directly on the host. No VMs, minimal
overhead. (The Docker hosts are themselves Proxmox LXCs, so still containers,
not VMs.)

## Two-layer model

The repo separates *how* a service runs from *where* it runs:

- `services/<name>/compose.yaml` defines **how** one service runs. It is
  self-contained and host-agnostic.
- `hosts/<label>/compose.yaml` selects **what** runs on a given host by pulling
  services in with Compose `include:`. Placement lives here.

`<label>` (`pve1`, `pve2`) is a logical name, not the machine hostname. The
pve2 Docker host, for example, is an unprivileged Proxmox LXC whose actual
hostname is `media`. The deploy picks the right dir from `HOMELAB_HOST` set in
the systemd unit, never from `$(hostname)`.

## Layout

```
Homelab/
├── services/                  # HOW: one self-contained service per folder
│   ├── portainer/             # container management UI (observe-only)
│   └── uptime-kuma/           # uptime / status monitoring
├── hosts/                     # WHAT: placement, one folder per Docker host
│   ├── pve1/                  # compose.yaml (include:) + .env.example
│   └── pve2/                  # compose.yaml (include:) + .env.example
└── tools/                     # host-level config, not containers
    ├── deploy.sh              # GitOps reconcile (pull + compose up)
    ├── systemd/               # timer + service that run deploy.sh
    ├── docker/                # Docker daemon config (daemon.json)
    └── cronjobs/              # host cron helpers (e.g. tailscale cert renew)
```

## How deploys work (GitOps)

`main` is authoritative. Each Docker host runs `tools/deploy.sh` on a systemd
timer (`tools/systemd/`, every 2 minutes). Each run:

1. `git reset --hard origin/main`, so the working tree matches the repo exactly.
2. `docker compose pull`, then `up -d --remove-orphans` for this host's stack.

Two consequences follow:

- **Never edit the repo on a host.** Tracked changes are discarded on the next
  reconcile. Push to `main` instead and the change lands within ~2 minutes.
- **Your `.env` files survive.** They are gitignored and untracked, so the hard
  reset leaves them alone. Per-host config lives in `hosts/<label>/.env` (copied
  from `.env.example`) and is loaded via `--env-file`.

See [`hosts/README.md`](./hosts/README.md) for the placement layer and
[`tools/systemd/README.md`](./tools/systemd/README.md) for installing the timer.
For one-off manual runs of a single service, see
[`services/README.md`](./services/README.md).

## Adding a new service

1. Create `services/<name>/compose.yaml` describing how it runs. Give its
   top-level `volumes:`/`networks:` keys **unique names** (e.g. `immich_data`,
   not `data`); see the include gotcha below.
2. Add an `include:` line for it to the target host's
   `hosts/<label>/compose.yaml`.
3. Add any new variables to that host's `hosts/<label>/.env.example` (and set
   the real values in the host's `.env`).
4. Commit and push. The timer deploys it within ~2 minutes.

**Include gotcha:** a host's `include:`d services merge into one Compose
project, so top-level `volumes:`/`networks:` keys must be unique across every
service on that host. Two services both keyed `data` collide; use
`portainer_data`, `uptime_kuma_data`, and so on.

## Operations

**Deploy user.** The repo lives at `/opt/homelab`, owned by a `deploy` user in
the `docker` group. All repo and compose commands run as `deploy`. Installing
the systemd units is the only step that needs root. Never operate the repo as
root.

**Reboot survival** needs all three links in the chain, top to bottom:

1. The Proxmox LXC set to `onboot: 1` (starts the Docker host).
2. The Docker service enabled inside the container (`systemctl enable docker`).
3. `restart: always` on each service in its compose file.

**Portainer observes, the repo deploys.** Portainer is for logs, stats, and
restarts only. Do not create stacks or containers in its UI: that makes state
outside the repo, which fights the next GitOps reconcile.

**Updates come from the tag you pin.** The reconcile's `docker compose pull`
updates each image according to its tag. A floating tag (`:latest`, Portainer)
updates every run; a major-pinned tag (`:1`, Uptime Kuma) updates within that
major only. The tag you choose is the update policy.

**Access.** The repo is public and cloned over HTTPS. If it goes private, switch
each host's clone to SSH with a read-only deploy key.
