# Desktop graphics

The desktop includes Mesa OpenGL and Vulkan drivers for both 64-bit applications and Steam's 32-bit runtime. To use an integrated GPU on a Linux host, the host must expose `/dev/dri` to Docker. Uncomment the DRI device and group arguments in `devcontainer.json`, then rebuild the container. The `--group-add=109` argument assumes the host's render group is GID 109; replace it with the GID shown by `stat -c '%g' /dev/dri/renderD128` on the host if needed.

This passthrough is optional so the dev container still builds on hosts without a GPU. It cannot provide hardware acceleration when the host or its container runtime does not expose `/dev/dri` (including hosted environments without GPU passthrough).

## Optional host storage

To use storage from the host in the desktop, first mount the drive on the host and make sure the host user can access its directory. Set the host environment variable `VUS_STORAGE_PATH` to that directory (for example, `export VUS_STORAGE_PATH=/media/$USER/my-drive` in the shell that launches VS Code), then uncomment the `mounts` block in `devcontainer.json` and rebuild the container. If VS Code is already open, restart it from the shell with the variable set. The directory will be available inside the container at `/mnt/device-storage`; files written there use the host drive's capacity and persist outside the container.

This is a bind mount, not direct device passthrough: the drive must already be mounted by the host and made available to the container runtime. The default configuration does not mount any host storage.

Browser cookies are small pieces of website state, not file storage, and cannot increase available disk space. Use the mounted directory for extra files instead.

## Transfer files from an iPad

The desktop container starts a private file-transfer page on port `8080`. In VS Code, open the **Ports** view, open the forwarded **iPad File Transfer** port in a browser, and open that forwarded address in Safari on the iPad. Choose files in the page and upload them; downloads are also available from the file list. Uploads are limited to 1 GiB per file, and existing files are not overwritten.

Uploads are saved in `~/iPad-Transfers`, or in `/mnt/device-storage/iPad-Transfers` when the optional host-storage mount above is configured. Configure that mount to use the capacity of a drive attached to the desktop host; the iPad itself cannot be mounted as extra desktop storage by this transfer page.

The page uses VS Code's private forwarded-port access; do not change the port visibility to public. The iPad must be able to reach the VS Code forwarded address, and may need to sign in to the same VS Code account. This is a file transfer page, not an SMB share; it copies files to or from the desktop and does not make iPad storage available as a Steam library. Satisfactory must be installed to storage accessible to the desktop.
