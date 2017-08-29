# Dietstack Horizon docker container build on Debian Stretch docker image

Important variable is HORIZON_HTTP_PORT which sets on what TCP port will container listen.

## Usage:

```
docker run -d --net=host \
           -e DEBUG="true" \
           -e HORIZON_HTTP_PORT=$PORT \
           --name horizon \
           dietstack/horizon:latest
```

## Themes

Horizon themes are located in `themes` dir.


