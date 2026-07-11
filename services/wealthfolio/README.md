# Wealthfolio

Self-hosted investment/portfolio tracker: a single container with a SQLite
database. Reachable at `https://money.dominicrousseau.com` over the LAN or
tailnet only — unlike BookOrbit it has **no** Cloudflare Tunnel public
hostname, so it is never exposed to the internet. The container publishes no
host ports, so there is no path around Caddy.

Auth is Wealthfolio's own password login (Argon2id hash + JWT sessions) — no
Basic Auth at Caddy, and none is needed. There is no setup wizard: first
visit goes straight to the login page.

Config comes from `hosts/<label>/.env` — see the `WEALTHFOLIO_*` block in
[`hosts/pve2/.env.example`](../../hosts/pve2/.env.example).

## Secrets

Two values, both set in `hosts/pve2/.env` on the host:

- **`WEALTHFOLIO_SECRET_KEY`** — `openssl rand -base64 32`. Encrypts stored
  secrets (market-data API keys, etc.) and signs login JWTs. **Back it up**:
  losing it means losing every encrypted secret the app has stored.
- **`WEALTHFOLIO_AUTH_PASSWORD_HASH`** — Argon2id PHC hash of the web login
  password. Generate it on the host (single-quote it in `.env` — the hash
  contains `$`):

  ```sh
  printf '%s' 'your-password' | docker run --rm -i alpine sh -c \
    "apk add -q argon2 && argon2 $(openssl rand -hex 8) -id -e"
  ```

## Rotating credentials

- **Login password:** generate a new hash (command above), put it in
  `WEALTHFOLIO_AUTH_PASSWORD_HASH` in `hosts/pve2/.env` (single-quoted!).
  The next reconcile recreates the container with the new value. Existing
  sessions stay valid until their JWT expires (60 min default).
- **`WEALTHFOLIO_SECRET_KEY`:** avoid rotating — it invalidates every
  session *and* makes previously stored encrypted secrets (API keys)
  unreadable; you would re-enter them in the UI afterwards.

## Backups

Single-part: everything (SQLite database, encrypted secrets file, addons)
lives in the `wealthfolio_data` volume. Snapshot it with the container
stopped for a consistent SQLite copy:

```sh
docker stop wealthfolio
docker run --rm -v wealthfolio_data:/data -v /srv/backups:/backup alpine \
  tar czf /backup/wealthfolio-$(date +%F).tgz -C /data .
docker start wealthfolio
```

Restore is the reverse: untar into a fresh `wealthfolio_data` volume, plus
the matching `WEALTHFOLIO_SECRET_KEY` in `.env` (without it the encrypted
secrets in the backup are unreadable).
