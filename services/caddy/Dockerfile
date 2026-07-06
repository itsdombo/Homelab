# Caddy with the Cloudflare DNS plugin compiled in. The official caddy image
# ships no plugins, and the DNS-01 ACME challenge needs the provider module,
# so we build a custom binary with xcaddy.
#
# Major-pinned (:2) to match the repo's tag-based update policy. To update,
# rebuild this image (see the note in compose.yaml) so the pull-only reconcile
# does not silently skip it.
FROM caddy:2-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM caddy:2

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
