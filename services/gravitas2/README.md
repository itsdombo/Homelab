# gravitas2 — Minecraft (All The Mods - Gravitas²)

Minecraft server running the **All The Mods - Gravitas²** CurseForge modpack,
**modpack version 0.9.4**, via the `itzg/minecraft-server` image. Runs on the
**pve1** host (included from [`hosts/pve1/compose.yaml`](../../hosts/pve1/compose.yaml)).

## Facts

- **Modpack:** All The Mods - Gravitas², modpack version 0.9.4, installed via
  `TYPE=CURSEFORGE` from a **locally-provided server-pack zip** — no CurseForge
  API key. See "Installing / updating the pack" below.
- **Memory:** `6G` JVM heap in a **7G** (≈6.9G available) container — the
  remaining ~1G is headroom for JVM overhead and the OS. Do not raise `MEMORY`
  without giving the container more RAM.
- **Storage:** world + mod data bind-mounted at **`/opt/appdata/gravitas2`**
  (SSD tier) → `/data` in the container. Create this directory before the first
  deploy. 102G disk / ~96G free is ample for the pack.
- **Port:** `25565/tcp` published on the host.

## Installing / updating the pack

The server installs from a **server-pack zip you download once**, kept on the
host at `/opt/appdata/gravitas2-packs/` (mounted read-only at `/modpacks`).
`CF_SERVER_MOD` in `compose.yaml` names the file
(`gravitas2-server-0.9.4.zip`). This avoids the CurseForge API entirely — the
website `/download/<id>/file` URL is bot-protected (HTTP 403) and the API
mechanism needs an account key, so a local file is the simplest reliable path.

Get the zip: on the modpack's CurseForge **Files** page, open the 0.9.4 file
and download its **Server Pack** (under "Additional Files"). The actual bytes
come from `*.forgecdn.net`, which *is* directly fetchable — so you can grab the
CDN link and pull it straight onto the host, e.g.:

```sh
mkdir -p /opt/appdata/gravitas2-packs
curl -L -o /opt/appdata/gravitas2-packs/gravitas2-server-0.9.4.zip \
  'https://mediafilez.forgecdn.net/files/7948/149/<exact-filename>.zip'
```

To update: download the new version's server pack, drop it in the same dir,
and change `CF_SERVER_MOD` in `compose.yaml` to the new filename, then push.

## First boot takes several minutes

On the **first** start the image downloads and installs the modpack — roughly
**370 mods** — before the server accepts connections. Expect several minutes of
apparent silence; watch progress with `docker logs -f gravitas2`. Subsequent
boots reuse the installed `/opt/appdata/gravitas2` data and start quickly.

## Console access

The container runs with `stdin_open`/`tty`, so you can attach to the live
server console:

```sh
docker attach gravitas2      # Ctrl-p Ctrl-q to detach without stopping
```

## Notes

- `TYPE: CURSEFORGE` with `EULA: "TRUE"` — accepting the EULA is required by
  Mojang to run any server.
- `TZ` comes from `TIMEZONE` in `hosts/pve1/.env` (America/Vancouver).
