# Self-Hosted Services

Each folder here is one service, defined by a `compose.yaml` file. Shared
configuration and secrets live in a single `.env` file in this directory.

## First-time setup

Create your `.env` from the template and fill it in:

```sh
cp .env.example .env
# edit .env and set the values
```

## Start a service

From inside a service's folder (e.g. `services/portainer/`):

```sh
docker compose up -d
```

The `-d` runs it in the background. Compose automatically reads the `.env`
file in this `services/` directory.

## Stop a service

```sh
docker compose down
```

## Update a service to the latest image

```sh
docker compose pull      # download newer images
docker compose up -d     # recreate containers using them
docker image prune -f    # clean up the old images
```

## Start everything at once (optional)

Once you have several services, this brings them all up in one go:

```sh
for dir in */; do
  [ -f "$dir/compose.yaml" ] && (cd "$dir" && docker compose up -d)
done
```
