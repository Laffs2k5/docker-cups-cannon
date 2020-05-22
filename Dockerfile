
# Credits to:
#   https://github.com/jacobalberty/cups-docker
#   https://github.com/olbat/dockerfiles/tree/master/cupsd
#   https://sourceforge.net/projects/cups-bjnp/

FROM debian:buster-slim

ARG BUILD_DATE

ENV VOLUME=/config
ENV PREFIX=/usr/local/docker

LABEL org.label-schema.build-date=$BUILD_DATE

# Install Packages (basic tools, cups, basic drivers, HP drivers)
RUN apt-get update \
&& apt-get install -y \
  sudo \
  whois \
  cups \
  cups-client \
  cups-bsd \
  cups-filters \
  smbclient \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Save /etc/cups to recreate it when needed.
# Use symbolic links to redirect a few standard cups directories to the volume
RUN mkdir -p "${PREFIX}/skel/cups" && \
    mv /etc/cups "${PREFIX}/skel/cups/etc" && \
    ln -s "${VOLUME}/etc" /etc/cups && \
    ln -s "${VOLUME}/log" /var/log/cups

# Remove backends that don't make sense in a container.
RUN mkdir -p /usr/lib/cups/backend-available && \
    mv /usr/lib/cups/backend/parallel /usr/lib/cups/backend-available/ && \
    mv /usr/lib/cups/backend/serial /usr/lib/cups/backend-available/ && \
    mv /usr/lib/cups/backend/cups-brf /usr/lib/cups/backend-available/

# Add user and disable sudo password checking
# default admin credentials will be print:print
RUN useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/print \
  --shell=/bin/bash \
  --password=$(mkpasswd print) \
  print \
&& sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

# CUPS back-end for the canon printers using the proprietary USB over IP BJNP protocol
# https://sourceforge.net/projects/cups-bjnp/
COPY build-bjnp.sh ./build-bjnp.sh
RUN chmod +x ./build-bjnp.sh && \
    sync && \
    ./build-bjnp.sh && \
    rm -f ./build-bjnp.sh

# Healthcheck and entrypoint
COPY docker-healthcheck.sh ${PREFIX}/bin/docker-healthcheck.sh
COPY docker-entrypoint.sh ${PREFIX}/bin/docker-entrypoint.sh
RUN chmod +x \
    ${PREFIX}/bin/docker-healthcheck.sh \
    ${PREFIX}/bin/docker-entrypoint.sh
HEALTHCHECK CMD ${PREFIX}/bin/docker-healthcheck.sh

VOLUME ["${VOLUME}"]

# Expose SMB printer sharing
EXPOSE 137/udp 139/tcp 445/tcp

# Expose IPP printer sharing
EXPOSE 631/tcp 631/udp

ENTRYPOINT ${PREFIX}/bin/docker-entrypoint.sh /usr/sbin/cupsd -f