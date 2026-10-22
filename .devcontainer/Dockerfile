FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        dbus-x11 \
        fonts-dejavu-core \
        novnc \
        tigervnc-standalone-server \
        tigervnc-tools \
        xfce4 \
        xfce4-goodies \
    && rm -rf /var/lib/apt/lists/*