# Automatic deploys (systemd timer)

A `oneshot` service runs `tools/deploy.sh`; a timer fires it every 2 minutes.
That gives you pull-on-push (with up to ~2 min latency) and image
auto-updates, with no extra long-running service.

## One-time setup on each Docker host

1. **Clone the repo** to the path the unit expects (read-only deploy key —
   see the repo root README):

   ```sh
   git clone git@github.com:itsdombo/Homelab.git /opt/homelab
   ```

2. **Create this host's `.env`** from the template:

   ```sh
   cd /opt/homelab
   cp hosts/pve2/.env.example hosts/pve2/.env   # then edit it
   ```

3. **Install the units.** Edit `homelab-deploy.service` first and set
   `HOMELAB_HOST=` to this machine's logical name (`pve1` or `pve2`):

   ```sh
   sudo cp tools/systemd/homelab-deploy.* /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now homelab-deploy.timer
   ```

4. **Check it:**

   ```sh
   systemctl list-timers homelab-deploy.timer   # next/last run
   sudo systemctl start homelab-deploy.service  # force a run now
   journalctl -u homelab-deploy.service -n 30   # see what it did
   ```

## Changing the interval

Edit `OnUnitActiveSec=` in the timer (e.g. `5min`), then
`sudo systemctl daemon-reload && sudo systemctl restart homelab-deploy.timer`.
