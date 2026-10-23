FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus \
        dbus-x11 \
        libasound2t64 \
        fonts-dejavu-core \
        novnc \
        tigervnc-standalone-server \
        tigervnc-tools \
        xfce4 \
        xfce4-goodies \
        wget \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/firefox \
    && curl -fsSL "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" -o /tmp/firefox.tar.xz \
    && tar -xJf /tmp/firefox.tar.xz -C /opt/firefox --strip-components=1 \
    && ln -sf /opt/firefox/firefox /usr/local/bin/firefox