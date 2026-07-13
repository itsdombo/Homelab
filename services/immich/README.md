# Immich

Self-hosted photo/video library: the Immich server plus a CPU-only
machine-learning sidecar (smart search, face recognition), Valkey, and
Postgres. Reachable at `https://photos.dominicrousseau.com` over the LAN or
tailnet only — like Wealthfolio it has **no** Cloudflare Tunnel public
hostname, so the library itself is never exposed to the internet. The
containers publish no host ports, so there is no path around Caddy.

Auth is Immich's own login — no Basic Auth at Caddy, and none is possible:
the web and mobile apps authenticate API calls with their own Bearer tokens,
which Basic Auth would clobber (the same reason BookOrbit exempts `/api/*`).

Public sharing is a separate, deliberately tiny service:
[`services/immich-public-proxy/`](../immich-public-proxy/compose.yaml) at
`https://gallery.dominicrousseau.com` — see "Public sharing" below.

Config comes from `hosts/<label>/.env` — see the `IMMICH_*` block in
[`hosts/pve2/.env.example`](../../hosts/pve2/.env.example).

## Storage

Everything file-shaped — originals, thumbnails, transcodes, and Immich's
built-in database dumps — lives under one host directory,
`IMMICH_LIBRARY_PATH` (`/mnt/photos/library` on pve2), mounted at `/data` in
the server container. `/mnt/photos` is the `tank/photos` ZFS dataset (the
HDD pool), mounted into the LXC by the Proxmox node — not the SSD-backed
rootfs, which stays free for the OS, images, and the database. Create the
subdir **before** the first deploy:

```sh
sudo mkdir -p /mnt/photos/library
sudo chown deploy:deploy /mnt/photos/library
```

Postgres data (`immich_db_data`) and the ML model cache
(`immich_model_cache`) are named volumes on the rootfs (SSD) — deliberately,
since Immich recommends keeping the database on fast storage. The model
cache is disposable — deleting it just re-downloads the models (~500 MB) on
the next job.

## First-run setup

1. Visit `https://photos.dominicrousseau.com` and create the admin account.
   The first visit shows an open registration screen — do this promptly
   after deploy.
2. **Administration → Settings → Server Settings → External domain** =
   `https://gallery.dominicrousseau.com`. This makes Immich's "Copy shared
   link" button emit public gallery URLs instead of unreachable `photos.*`
   ones.
3. Mobile app: server URL `https://photos.dominicrousseau.com`, then log in.
   Works anywhere the tailnet does, including background photo backup.

## Public sharing (gallery.*)

immich-public-proxy (IPP) is the only internet-facing piece. It holds no
API key: it can only fetch albums/photos that were explicitly shared inside
Immich, and every other request 404s. Share an album in Immich, copy the
link — thanks to the External domain setting it points at
`https://gallery.dominicrousseau.com/share/...` and works for anyone,
including password-protected and expiring shares.

Never add `photos.*` as a Tunnel public hostname — that would expose the
whole library and cap uploads at Cloudflare's 100 MB limit. Optional
Cloudflare tweak: add a Cache Rule that **bypasses cache** for
`gallery.dominicrousseau.com/share/video/*` — the CDN cache can otherwise
interfere with video streaming.

## Secrets

One value, set in `hosts/pve2/.env` on the host:

- **`IMMICH_DB_PASSWORD`** — `openssl rand -hex 24`. Keep it alphanumeric;
  Immich's DB connection handling is picky about special characters.

## Rotating credentials

- **Postgres password:** two places must agree. First change it in the
  database, then in the env:

  ```sh
  docker exec -it immich-db psql -U immich -c "ALTER USER immich WITH PASSWORD 'NEW';"
  # then set IMMICH_DB_PASSWORD=NEW in hosts/pve2/.env
  ```

- **User passwords / sessions:** managed inside Immich (Administration →
  Users); nothing lives in `.env`.

## Backups (two-part!)

Like BookOrbit, state is split, and both halves are needed for a restore:

1. **Files:** the library dir (`IMMICH_LIBRARY_PATH`). Backing up the whole
   dir also captures the built-in DB dumps below.
2. **Database:** Immich dumps its own database nightly to
   `/mnt/photos/library/backups/` — verify it is enabled under
   **Administration → Settings → Backup Settings**. Manual dump:

   ```sh
   docker exec -t immich-db pg_dump --clean --if-exists -U immich immich | gzip > immich-$(date +%F).sql.gz
   ```

A files-only backup loses albums, users, and all metadata; a DB-only backup
loses the photos themselves. On restore, the Immich version must match the
dump's version — another reason the compose pins an exact tag.

## Updating

Immich ships breaking changes; updates are deliberate, not automatic. Read
the [release notes](https://github.com/immich-app/immich/releases), bump the
`immich-server` and `immich-machine-learning` tags together in
`compose.yaml` (and the valkey/postgres digests only when the release
compose changes them), then push.
