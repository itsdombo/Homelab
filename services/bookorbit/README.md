# BookOrbit

Self-hosted ebook library: a Node app plus a Postgres (pgvector) database.
Reachable at `https://books.dominicrousseau.com`, published to the internet
through the Cloudflare Tunnel (`services/cloudflared/`) and password-protected
with HTTP Basic Auth at Caddy. The app container publishes no host ports, so
there is no path around Caddy.

Basic Auth covers the pages; `/api/*` and static assets are exempt (see the
Caddyfile for why — the frontend's own `Authorization: Bearer` header would
otherwise clobber the Basic credentials and 401 every API call). The API is
still protected on every route by BookOrbit's own JWT/KOReader auth; Basic
Auth is the extra gate on the UI against scanners and drive-by logins.

Config comes from `hosts/<label>/.env` — see the `BOOKORBIT_*` block in
[`hosts/pve2/.env.example`](../../hosts/pve2/.env.example).

## Adding a book (Book Dock)

Book Dock is the only ingestion path — no external sync tool watches the
books folder.

1. Drop the file into the Book Dock folder (`BOOKORBIT_DOCK_PATH` on the
   host). Browser upload or drag-and-drop into the UI lands in the same
   place. Use **Rescan** in the UI if a directly-copied file isn't picked up.
2. BookOrbit extracts embedded metadata and the cover, then runs the
   configured metadata providers automatically.
3. In the Book Dock UI, review the metadata, fix anything, pick the
   destination library, and **Finalize**. The file is moved out of the dock
   into the library (`BOOKORBIT_BOOKS_PATH`) and becomes a normal book.

That's it — there is no separate "add book" step. For fully hands-off intake,
enable auto-finalize ("safe merge") in Book Dock's settings; predictable files
then skip step 3 entirely.

## KOReader plugin (Kindle)

BookOrbit ships a native KOReader plugin: catalog browsing on the device plus
two-way progress and annotation sync. This is richer than plain OPDS.

1. In BookOrbit: **Settings → Integrations → KOReader**, create the device
   account, then click **Download Plugin**. The `bookorbit.koplugin.zip` is
   preconfigured with the server URL and credentials — nothing to type on
   the device.
2. Unzip and copy the `bookorbit.koplugin` folder into `koreader/plugins/`
   on the Kindle (jailbroken, running KOReader), then restart KOReader.
3. On the device: **Tools → BookOrbit Sync** for the catalog browser,
   downloads, and manual/automatic sync.

**Basic Auth note:** the plugin talks to `/api/*` with its own KOReader
credentials, and that whole path is already exempt from Caddy's Basic Auth
(the exemption the web frontend itself requires — see the Caddyfile), so the
plugin works without extra configuration. If the device ever gets auth
errors, check whether it is requesting a path outside `/api/` and extend the
`@protected` matcher's exemption list accordingly.

## Rotating credentials

- **Basic Auth password:** run `docker exec -it caddy caddy hash-password`,
  put the new hash in `BOOKORBIT_BASIC_AUTH_HASH` in `hosts/pve2/.env`
  (single-quoted!). The next reconcile recreates Caddy with the new value.
- **JWT_SECRET:** generate a new `openssl rand -hex 32` into
  `BOOKORBIT_JWT_SECRET`. Every session is invalidated — users log in again;
  if device sync breaks, re-download the KOReader plugin package.
- **Postgres password:** two places must agree. First change it in the
  database, then in the env:

  ```sh
  docker exec -it bookorbit-db psql -U bookorbit -c "ALTER USER bookorbit WITH PASSWORD 'NEW';"
  # then set BOOKORBIT_POSTGRES_PASSWORD=NEW in hosts/pve2/.env
  ```

- **SETUP_BOOTSTRAP_TOKEN** is one-time; blank it after the setup wizard.

## Backups (two-part!)

Unlike a single-file SQLite app, BookOrbit's state is split, and both halves
are needed for a restore:

1. **Files:** the library dir (`BOOKORBIT_BOOKS_PATH`) plus the
   `bookorbit_app_data` volume (covers/app state).
2. **Database:** `docker exec bookorbit-db pg_dump -U bookorbit bookorbit > bookorbit.sql`,
   or snapshot the `bookorbit_db_data` volume with the container stopped.

A files-only backup loses users, reading progress, and annotations; a DB-only
backup loses the books themselves.
