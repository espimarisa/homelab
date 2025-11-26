# Builds the image.
FROM caddy:2-builder-alpine AS builder
RUN xcaddy build \
	--with github.com/mholt/caddy-dynamicdns \
	--with github.com/fvbommel/caddy-combine-ip-ranges

# Creates the full image.
FROM caddy:2-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
ENTRYPOINT ["/usr/bin/caddy"]

# Runs Caddy.
CMD ["run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
