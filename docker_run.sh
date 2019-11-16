#!/bin/bash

sudo ufw allow 631/tcp
sudo ufw allow 631/udp

docker run \
    -d \
    --name cups-cannon \
    --network host \
    cups-cannon:latest
