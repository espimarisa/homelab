# Vaultwarden

Vaultwarden is an unofficial Bitwarden-compatible server. It's very lightweight and fully compatible with all of the lovely Bitwarden apps.

Before starting Vaultwarden, you will need to take ownership of the volume properly.

```sh
# replace 1000:1000 with your puid/pgid and /var/bla to wherever you have docker
sudo chown -R 1000:1000 /var/lib/docker/volumes/vaultwarden-volume
```

## Admin portal access

After deploying Vaultwarden, head on over to `https://${VAULTWARDEN_URL}/admin` and enter your admin token. Note that this is the _raw_ token, not the argon2-encrypted token.

You will want to make sure that all diagnostics pass. If you get header issues, double-check your host. Cloudflare is notorious for trying to force headers onto clients, and they have some stupid feature that I forget the name of on by default that breaks 2FA notifications.

## Notification support

For notification support, you need a `VAULTWARDEN_PUSH_INSTALLATION_ID` and `VAULTWARDEN_PUSH_INSTALLATION_KEY` set in `.env`. You can get these values by submitting a form (no actual data is needed, it's just for the API) over on [Bitwarden's side of things](https://bitwarden.com/host/).

I'm not gonna lie, I never have gotten a notification. I assume it's for Duo, but I can't be bothered to read into the docs. Surely it works?
