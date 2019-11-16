# docker-cups-cannon
CUPS container with Canon BJNP protocol support

## Build
```
docker build \
    --rm \
    --tag cups-cannon:latest \
    .
```

## Run
```
docker run \
    -d \
    --name cups-cannon \
    --network host \
    cups-cannon:latest
```

**Note:** port 631 must be accessible outside the docker host. On Ubuntu: `sudo ufw allow 631/tcp; sudo ufw allow 631/udp`

## Credits to:
https://github.com/jacobalberty/cups-docker

https://github.com/olbat/dockerfiles/tree/master/cupsd

https://sourceforge.net/projects/cups-bjnp/