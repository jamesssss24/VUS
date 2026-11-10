# Desktop graphics

The desktop forces Mesa's `llvmpipe` OpenGL renderer, which implements graphics in software on the CPU. VirtualGL (`vglrun`) and Mesa's Vulkan software renderer (`lavapipe`) are also installed. Software rendering provides graphics without a host GPU, but it is not an emulated Intel/AMD iGPU: it does not provide hardware acceleration and is much slower, especially for games.

To use an integrated GPU on a Linux host instead, the host must expose `/dev/dri` to Docker. Add the DRI device and the host render-device group to `runArgs` in `devcontainer.json`, then rebuild the container. Use the group ID shown by `stat -c '%g' /dev/dri/renderD128` on the host.

GPU passthrough cannot provide hardware acceleration when the host or its container runtime does not expose `/dev/dri` (including hosted environments without GPU passthrough).

## Free cloud desktop option

GitHub Codespaces has a monthly included-usage quota; it is not an unlimited free host. [Oracle Cloud Always Free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm) offers an Ampere A1 allocation of up to 2 OCPUs and 12 GB RAM, subject to account limits, home-region capacity, and Oracle's idle-instance reclamation policy. A1 is ARM-based, but this repository's container is x86_64 and includes 32-bit Steam components. You can try it under QEMU user-mode emulation with the dedicated [`devcontainer.oracle-x86-emulation.json`](./devcontainer.oracle-x86-emulation.json) profile. Emulation can be very slow, especially during image builds and graphics workloads; this is a best-effort way to run the desktop, not a guarantee that Steam games will work well.

To try the emulated x86 profile:

1. In the [Oracle Cloud Console](https://cloud.oracle.com/), create an Always Free Ampere A1 Linux VM in your home region. Stay within the Always Free CPU, memory, and storage allowances; capacity may be unavailable.
2. Add your SSH public key and restrict SSH ingress to your IP. Do not expose desktop ports `6080`, `6082`, or `8080` publicly.
3. Install Docker on the VM and register amd64 emulation with QEMU/binfmt, following [Docker's QEMU instructions](https://docs.docker.com/build/building/multi-platform/#install-qemu-manually). One option is:

   ```sh
   docker run --privileged --rm tonistiigi/binfmt --install amd64
   docker run --rm --platform linux/amd64 ubuntu:24.04 uname -m
   ```

   The test should print `x86_64`. This privileged binfmt setup changes the VM host's executable-format handlers; only run it on a VM you administer.

4. Connect with VS Code Remote - SSH and install the [Dev Containers CLI](https://github.com/devcontainers/cli) if needed. Clone the repository and start the emulation profile:

   ```sh
   git clone https://github.com/jamesssss24/VUS.git
   cd VUS
   devcontainer up --workspace-folder "$PWD" --config .devcontainer/devcontainer.oracle-x86-emulation.json
   ```

   Then use **Dev Containers: Attach to Running Container**. Build and runtime use `linux/amd64` emulation; the regular Codespaces profile remains unchanged.
5. Back up or push any Codespaces edits and separately transfer untracked files and personal data. A Git clone does not copy the Codespaces container's local files.
6. Monitor Oracle's free-tier limits and idle-instance policy. Oracle may reclaim an Always Free VM that stays below its CPU, network, and (for A1) memory utilization thresholds for seven days. Review the current limits before storing anything irreplaceable there.

Oracle Always Free is the closest fit for a no-GPU cloud desktop, but x86 emulation does not provide GPU acceleration and does not guarantee that Steam games will be usable or that the VM will remain available. Oracle's free AMD E2.1.Micro VMs are native x86 but too small for this full desktop. If you need good Steam performance and persistent availability, use a local machine or a paid x86 VM instead.

## Browser connectivity

Firefox is installed from Mozilla's APT repository rather than Ubuntu's Snap-only package, so it works in the container without `snapd`. The desktop Firefox launcher and terminal command use the same executable and direct internet connection; no third-party proxy is configured.

## Accessing the noVNC desktop

Open **Desktop (noVNC)** from the VS Code **Ports** view while signed in to the GitHub account that can access this Codespace. Port `6080` is intentionally private. A `401` from the Codespaces forwarding URL is an access-authentication response, not a noVNC login prompt; do not make the port public because the desktop service does not add its own web authentication.

As an alternative, authenticate GitHub CLI on a machine that can run `gh`, then forward the private port locally:

```sh
gh auth login
gh codespace ports forward 6080:6080 --codespace <codespace-name>
```

Open `http://127.0.0.1:6080/vnc.html` on that same machine while the command is running. Find the Codespace name with `gh codespace list`.

The desktop startup watchdog monitors the XFCE session and TurboVNC backend and restarts them if they exit. If the connection drops during recovery, refresh the noVNC page after port `6080` is available again.

## Desktop audio in a browser

After rebuilding with **Dev Containers: Rebuild Container**, the TurboVNC startup script starts PulseAudio routing and exposes application audio through the **Desktop Audio** receiver on private forwarded port **6082**. In the VS Code **Ports** view, open **Desktop Audio** in a browser and press **Start Receiver**. The receiver defaults to this desktop's audio and also supports external HTTP and Icecast/Shoutcast streams, volume and mute controls, a visualizer, and a synthetic test tone. External sender ports (such as 8085) are separate from the receiver page's forwarded port, which remains **6082**; the browser must be able to reach external stream addresses directly. This is a separate audio stream; TurboVNC/noVNC does not carry audio in the desktop page itself.

Audio playback requires a browser that can reach the VS Code forwarded port. The receiver and stream are private and should not be made public. Remote custom streams can play without CORS support, but browser security may prevent the visualizer from analyzing them.

## Optional host storage

To use storage from the host in the desktop, first mount the drive on the host and make sure the host user can access its directory. Set the host environment variable `VUS_STORAGE_PATH` to that directory (for example, `export VUS_STORAGE_PATH=/media/$USER/my-drive` in the shell that launches VS Code), then uncomment the `mounts` block in `devcontainer.json` and rebuild the container. If VS Code is already open, restart it from the shell with the variable set. The directory will be available inside the container at `/mnt/device-storage`; files written there use the host drive's capacity and persist outside the container.

This is a bind mount, not direct device passthrough: the drive must already be mounted by the host and made available to the container runtime. The default configuration does not mount any host storage.

Browser cookies are small pieces of website state, not file storage, and cannot increase available disk space. Use the mounted directory for extra files instead.

## Transfer files from an iPad

The desktop container starts a private file-transfer page on port `8080`. In VS Code, open the **Ports** view, open the forwarded **iPad File Transfer** port in a browser, and open that forwarded address in Safari on the iPad. Choose files in the page and upload them; downloads are also available from the file list. Uploads are limited to 1 GiB per file, and existing files are not overwritten.

Uploads are saved in `~/iPad-Transfers`, or in `/mnt/device-storage/iPad-Transfers` when the optional host-storage mount above is configured. Configure that mount to use the capacity of a drive attached to the desktop host; the iPad itself cannot be mounted as extra desktop storage by this transfer page.

The page uses VS Code's private forwarded-port access; do not change the port visibility to public. The iPad must be able to reach the VS Code forwarded address, and may need to sign in to the same VS Code account. This is a file transfer page, not an SMB share; it copies files to or from the desktop and does not make iPad storage available as a Steam library. Satisfactory must be installed to storage accessible to the desktop.
