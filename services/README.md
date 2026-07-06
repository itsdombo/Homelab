# Self-Hosted Services

Each folder here is one service, defined by a self-contained `compose.yaml`.
A service file describes only *how* that service runs, never where. Placement
lives in [`hosts/`](../hosts/README.md).

## How these actually deploy

In normal operation you do **not** run these by hand. Each Docker host runs
`tools/deploy.sh` on a systemd timer, which reconciles the host's stack from
`hosts/<label>/compose.yaml`. Environment variables come from
`hosts/<label>/.env` (loaded via `--env-file`), not from this directory. See
[`hosts/README.md`](../hosts/README.md) and
[`tools/systemd/README.md`](../tools/systemd/README.md).

## One-off manual runs (testing)

You can still bring a single service up by hand to test it. From inside its
folder:

```sh
cd services/uptime-kuma
docker compose up -d
```

If the service interpolates host variables (e.g. `${TIMEZONE}`), point Compose
at a host env file so they resolve:

```sh
docker compose --env-file ../../hosts/pve2/.env up -d
```

Stop it again with:

```sh
docker compose down
```

## Update a service to a newer image

```sh
docker compose pull      # download a newer image per the pinned tag
docker compose up -d     # recreate the container using it
docker image prune -f    # reclaim disk from the old image
```

The automated deploy does exactly this on every reconcile, so manual updates
are only for testing.
