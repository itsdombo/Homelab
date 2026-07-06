# Automatic deploys (systemd timer)

A `oneshot` service runs `tools/deploy.sh`; a timer fires it every 2 minutes.
That gives you pull-on-push (with up to ~2 min latency) plus image
auto-updates, with no extra long-running service.

The repo runs as an unprivileged `deploy` user (in the `docker` group), not as
root. Only installing the units below needs `sudo`; do everything else as
`deploy`.

## One-time setup on each Docker host

1. **Create the deploy user and repo dir** (root, once):

   ```sh
   sudo useradd -r -s /usr/sbin/nologin -G docker deploy
   sudo install -d -o deploy -g deploy /opt/homelab
   ```

2. **Clone the repo** as `deploy`. The repo is public, so clone over HTTPS:

   ```sh
   sudo -u deploy git clone https://github.com/itsdombo/Homelab.git /opt/homelab
   ```

   If the repo ever goes private, switch to SSH with a read-only deploy key:

   ```sh
   sudo -u deploy git clone git@github.com:itsdombo/Homelab.git /opt/homelab
   ```

3. **Create this host's `.env`** from the template (as `deploy`):

   ```sh
   cd /opt/homelab
   sudo -u deploy cp hosts/pve2/.env.example hosts/pve2/.env   # then edit it
   ```

4. **Install the units** (root). Edit `homelab-deploy.service` first: set
   `HOMELAB_HOST=` to this machine's logical name (`pve1` or `pve2`), and make
   sure it runs as the deploy user by adding `User=deploy` and `Group=docker`
   under `[Service]`:

   ```sh
   sudo cp tools/systemd/homelab-deploy.* /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now homelab-deploy.timer
   ```

5. **Check it:**

   ```sh
   systemctl list-timers homelab-deploy.timer   # next/last run
   sudo systemctl start homelab-deploy.service  # force a run now
   journalctl -u homelab-deploy.service -n 30   # see what it did
   ```

## Changing the interval

Edit `OnUnitActiveSec=` in the timer (e.g. `5min`), then:

```sh
sudo systemctl daemon-reload && sudo systemctl restart homelab-deploy.timer
```
