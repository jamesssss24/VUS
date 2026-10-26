# Copilot instructions: Linux desktop environment

Keep repository guidance focused on the Linux desktop environment configured in `.devcontainer/`; the repository's other applications and launcher content are outside this scope.

## Build, test, and lint

The desktop environment is built as a VS Code Dev Container from `.devcontainer/Dockerfile`. It enables Ubuntu's multiverse repository and the `i386` architecture to install Steam and its 32-bit runtime dependencies. There are no repository-defined test or lint suites.

- Build or rebuild the environment using VS Code's **Dev Containers: Rebuild Container** command.
- The container starts the desktop automatically through `postStartCommand` in `.devcontainer/devcontainer.json`.
- Check the startup script's shell syntax with:

  ```bash
  bash -n .devcontainer/start-desktop.sh
  ```

- To exercise startup and readiness, run the script inside the configured Ubuntu-based container:

  ```bash
  bash .devcontainer/start-desktop.sh
  ```

  Success means the script exits with status 0 after noVNC responds at `http://127.0.0.1:6080/vnc.html` and TigerVNC accepts connections on `127.0.0.1:5901`. There are no individual automated test cases to select.

## Architecture and conventions

- `.devcontainer/devcontainer.json` is the entry point: it builds the image, forwards port `6080`, and runs the desktop startup script after container start. Its seccomp and AppArmor settings allow Steam and GTK's Glycin image-loader sandbox to create namespaces. Keep the forwarded port and the script's noVNC listener in sync.
- `.devcontainer/Dockerfile` installs the Ubuntu desktop stack (XFCE, TigerVNC, noVNC, and D-Bus), Steam with its distro-managed dependencies, and Firefox. It enables the `i386` architecture and multiverse repository for Steam; keep those settings if changing Steam packages. Add or change system dependencies here rather than relying on undocumented packages already present in a running container.
- `.devcontainer/start-desktop.sh` is an idempotent startup/setup script. It validates the OS, starts and verifies the system D-Bus, configures the VNC session to launch XFCE, starts TigerVNC on display `:1`, and starts the noVNC proxy. Preserve its fail-fast behavior and explicit diagnostics when changing startup steps.
- The startup script also writes per-user browser and environment configuration. Keep related settings consistent between those generated files; avoid duplicating configuration in unrelated files.
- The desktop container is expected to run on Ubuntu or Debian. If changing the base image, update the OS check and verify package names and startup behavior for that image.
- The desktop is accessed through noVNC on forwarded port `6080`; VNC itself listens locally in the container. Keep VNC bound to localhost unless the network exposure is being deliberately redesigned.
