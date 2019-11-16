#!/bin/bash
set -e
SOURCEDIR=/sources

BUILD_DEPS="
    autoconf \
    build-essential \
    curl \
    dpkg-dev \
    g++ \
    gcc \
    make \
    libcups2-dev \
    libcupsimage2-dev"

apt-get update
apt-get install -qy --no-install-recommends ${BUILD_DEPS}
mkdir -p "${SOURCEDIR}"
cd "${SOURCEDIR}"
curl https://vorboss.dl.sourceforge.net/project/cups-bjnp/cups-bjnp/2.0.2/cups-bjnp-2.0.2.tar.gz | tar xz
cd cups-bjnp-2.0.2 && ./configure --prefix=/usr
make
make install
cd /
rm -rf "${SOURCEDIR}"
apt-get purge -qy --auto-remove ${BUILD_DEPS}
rm -rf /var/lib/apt/lists/*
