# gravitas2 — Minecraft (All The Mods - Gravitas²)

Minecraft server running the **All The Mods - Gravitas²** CurseForge modpack,
**modpack version 0.9.4**, via the `itzg/minecraft-server` image. Runs on the
**pve1** host (included from [`hosts/pve1/compose.yaml`](../../hosts/pve1/compose.yaml)).

## Facts

- **Modpack:** All The Mods - Gravitas² (installed via `TYPE=AUTO_CURSEFORGE`,
  pinned to CurseForge `CF_SLUG=all-the-mods-gravitas2` / `CF_FILE_ID=7948149`),
  modpack version 0.9.4.
- **CurseForge API key:** required. `AUTO_CURSEFORGE` uses the official API, so
  set `CF_API_KEY` in `hosts/pve1/.env` (free key from
  <https://console.curseforge.com/>). The old website-URL fetch is blocked by
  bot protection (HTTP 403), which is why this uses the API mechanism.
- **Memory:** `6G` JVM heap in a **7G** (≈6.9G available) container — the
  remaining ~1G is headroom for JVM overhead and the OS. Do not raise `MEMORY`
  without giving the container more RAM.
- **Storage:** world + mod data bind-mounted at **`/opt/appdata/gravitas2`**
  (SSD tier) → `/data` in the container. Create this directory before the first
  deploy. 102G disk / ~96G free is ample for the pack.
- **Port:** `25565/tcp` published on the host.

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
