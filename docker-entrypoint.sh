#!/bin/bash
set -e

# usage: replace conf var new_val
replace () {
    var=$2
    new_val=$3

    sed -i "s/^$var *= *.*/$var = $new_val/; s/^$var [^=]*$/$var $new_val/" "$1"
}

# etc/cups not initialized?
if [[ ! -e "${VOLUME}/etc/" ]]; then

    # cups: Restore saved etc/cups
    cp -R "${PREFIX}/skel/cups/etc" "${VOLUME}/"

    # cups: Logging to stderr
    replace "${VOLUME}/etc/cups-files.conf" AccessLog stderr
    replace "${VOLUME}/etc/cups-files.conf" ErrorLog stderr
    replace "${VOLUME}/etc/cups-files.conf" PageLog stderr

    ## cups: Baked-in config file changes
    sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' "${VOLUME}/etc/cupsd.conf" && \
    sed -i 's/Browsing Off/Browsing On/' "${VOLUME}/etc/cupsd.conf" && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' "${VOLUME}/etc/cupsd.conf" && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' "${VOLUME}/etc/cupsd.conf" && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' "${VOLUME}/etc/cupsd.conf" && \
    echo "ServerAlias *" >> "${VOLUME}/etc/cupsd.conf" && \
    echo "DefaultEncryption Never" >> "${VOLUME}/etc/cupsd.conf"

    # cups: Configure the service's to be reachable
    /usr/sbin/cupsd \
    && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
    && cupsctl --remote-admin --remote-any --share-printers \
    && kill $(cat /var/run/cups/cupsd.pid)
fi

# Ensure logdir exists and is owned by the correct group
if [[ ! -e "${VOLUME}/log" ]]; then
    mkdir -p "${VOLUME}/log"
    chgrp lp "${VOLUME}/log"
fi

$@
