# ddclient

ddclient is a Dynamic DNS client that I use to keep my primary infra A/AAAA records up-to-date with my home IP address in the chance my IP re-rolls.

To get ddclient setup, you need to configure `./config/ddclient.conf` to work with Glauca HexDNS (or whatever provider you use - I just use Glauca since they're my registrar).

You can get your credentials by [creating a dynamic DNS record](https://docs.glauca.digital/hexdns/dyndns/) in the HexDNS portal.

```sh
# copy example file to the required path
cp ./config/ddclient.example.conf ./config/ddclient.conf

# now, we will punch in our credentials.
# ....rest of file
login=glauca-login-from-the-record
password=glauca-password-from-the-record
# and, at the very bottom, we will need to put the target fqdn
# i personally use a single A/AAAA record for all internal services
# and CNAME alias anything to it I need, as ddclient only lets you do
# one service at a time anyways.
ddns.example.com
```
