FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install prerequisites and Mesa graphics libraries
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
        ffmpeg \
        fonts-dejavu-core \
        gnupg \
        libasound2t64 \
        libasound2-plugins \
        libgl1-mesa-dri \
        libgl1-mesa-dri:i386 \
        libglx-mesa0 \
        libglx-mesa0:i386 \
        mesa-utils \
        mesa-vulkan-drivers \
        mesa-vulkan-drivers:i386 \
        novnc \
        pulseaudio \
        pulseaudio-utils \
        software-properties-common \
        websockify \
        wget \
        x11-utils \
        xfonts-base \
        xfce4 \
        xfce4-goodies \
    # 2. Download and install TurboVNC v3.1.1 directly from GitHub Releases
    && wget -q https://github.com/TurboVNC/turbovnc/releases/download/3.1.1/turbovnc_3.1.1_amd64.deb -O /tmp/turbovnc.deb \
    && apt-get install -y /tmp/turbovnc.deb \
    && rm -f /tmp/turbovnc.deb \
    # 3. Download and install VirtualGL v3.1.5 directly from GitHub Releases
    && wget -q https://github.com/VirtualGL/virtualgl/releases/download/3.1.5/virtualgl_3.1.5_amd64.deb -O /tmp/virtualgl.deb \
    && apt-get install -y /tmp/virtualgl.deb \
    && rm -f /tmp/virtualgl.deb \
    && vglrun --version \
    # 4. Install Firefox via Official Mozilla Repository
    && install -d -m 0755 /etc/apt/keyrings \
    && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | tee /etc/apt/sources.list.d/mozilla.list > /dev/null \
    && printf '%s\n' 'Package: *' 'Pin: origin packages.mozilla.org' 'Pin-Priority: 1000' > /etc/apt/preferences.d/mozilla \
    && apt-get update \
    && apt-get install -y --allow-downgrades --no-install-recommends firefox \
    && firefox --version \
    && apt-get install -y --install-recommends steam-installer \
    && rm -rf /var/lib/apt/lists/*

# Add VirtualGL and TurboVNC to global PATH
ENV PATH="/opt/VirtualGL/bin:/opt/TurboVNC/bin:${PATH}"