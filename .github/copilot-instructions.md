# Copilot instructions for VUS

## Project snapshot

This repository is primarily a VS Code development container environment for a Linux desktop session, not a conventional application repo. The active project configuration lives in `.devcontainer/`, especially:

- `.devcontainer/devcontainer.json` defines the container, forwarded ports, and startup commands
- `.devcontainer/Dockerfile` builds the desktop environment
- `.devcontainer/start-vnc.sh` and `.devcontainer/start-desktop.sh` start the headless desktop and noVNC browser access
- `.devcontainer/audio-receiver.*` and `.devcontainer/stream-desktop-audio.sh` handle desktop audio forwarding
- `.devcontainer/ipad-transfer.py` provides the iPad file-transfer page

The root-level HTML and app-like folders appear to be historical artifacts or examples, not the canonical project structure. Treat `.devcontainer/` as the main system of interest unless a task explicitly names another directory.

## Build, test, and lint commands

There is no application build/test/lint pipeline for a normal project at the repo root.

- No repo-wide Node/Python/Rust package manifest or test runner was found.
- The container is built and started through the Dev Containers workflow, not through a package script.

Primary operations for this environment are:

```bash
cd /workspaces/VUS
# then use VS Code: "Dev Containers: Rebuild Container"
# or re-open in the container if already running
```

If you need to inspect or validate the desktop environment manually:

```bash
cd /workspaces/VUS/.devcontainer
bash start-vnc.sh
```

Then use the forwarded browser ports from VS Code (`6080` for noVNC desktop, `6082` for Desktop Audio, `8080` for iPad File Transfer).

## High-level architecture

- `.devcontainer/devcontainer.json` is the main entry point: it configures the Docker build, environment variables, forwarded ports, and the `postStartCommand` that launches the virtual desktop.
- The container uses Mesa llvmpipe/lavapipe software rendering so GUI apps can run without a host GPU.
- `start-vnc.sh` boots the desktop stack and exposes it through a browser-accessible VNC/noVNC endpoint.
- `audio-receiver.py` and `stream-desktop-audio.sh` route system audio through a private browser receiver, separate from the main desktop page.
- `ipad-transfer.py` serves a private file-transfer web page for moving files to/from the dev environment.
- The repo root contains a variety of unrelated HTML artifacts; do not assume they are part of the same current project.

## Key conventions and repository-specific patterns

- Treat `.devcontainer/` as the real operational project unless the user clearly points to some other folder.
- Do not add standard web-framework conventions or package tooling unless the task is explicitly about a specific app artifact in the repo root.
- Preserve the devcontainer workflow: changes that affect the desktop environment should be made in `.devcontainer/` and validated through the container/browser UI rather than by inventing a local build system.
- Be careful with port-sensitive features: `6080`, `6082`, and `8080` are intentionally exposed and labeled in `devcontainer.json`.
- If a change affects audio, graphics, or file transfer, validate through the forwarded browser endpoints, not by assuming a normal local app workflow.
- Root-level HTML files should be treated as disconnected artifacts unless a task explicitly says otherwise.

## Practical guidance for future sessions

- Start by checking `.devcontainer/` if the issue is about desktop setup, environment, ports, graphics, or audio.
- Avoid repo-wide assumptions about a web app architecture when the actual system is a containerized desktop environment.
- Prefer small, targeted edits in the relevant devcontainer script or config file over broad refactors.

## Files to read first

- `.devcontainer/devcontainer.json` for environment and port configuration
- `.devcontainer/README.md` for container behavior and usage notes
- `.devcontainer/Dockerfile` when troubleshooting the desktop image
- the exact script or config file named by the task

## Notes for future Copilot sessions

This workspace is a desktop-in-a-container environment, and the repo is best understood as a collection of devcontainer tooling plus miscellaneous artifacts. Default to container-specific fixes and avoid assuming a conventional app build/test pipeline.
