FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
        sed -i '/^Components:/ { /multiverse/! s/$/ multiverse/; }' /etc/apt/sources.list.d/ubuntu.sources; \
    elif [ -f /etc/apt/sources.list ]; then \
        sed -i '/^deb / { /multiverse/! s/$/ multiverse/; }' /etc/apt/sources.list; \
    fi \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus \
        dbus-x11 \
        libasound2t64 \
        libasound2-plugins \
        ffmpeg \
        fonts-dejavu-core \
        libgl1-mesa-dri \
        libgl1-mesa-dri:i386 \
        mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 \
        novnc \
        pulseaudio \
        pulseaudio-utils \
        tigervnc-standalone-server \
        tigervnc-tools \
        xfce4 \
        xfce4-goodies \
        wget \
    && apt-get install -y --install-recommends steam-installer \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/firefox \
    && curl -fsSL "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" -o /tmp/firefox.tar.xz \
    && tar -xJf /tmp/firefox.tar.xz -C /opt/firefox --strip-components=1 \
    && ln -sf /opt/firefox/firefox /usr/local/bin/firefox