# Docker Docs

Daemon configuration can be done by editing `/etc/docker/daemon.json`.

```json
{
	"data-root": "/docker",
	"experimental": true,
	"fixed-cidr-v6": "MATCH_DOCKER_ULA_BASE_VAR:0::/64",
	"ip6tables": true,
	"ipv6": true
}
```
