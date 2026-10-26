# Desktop graphics

The desktop includes Mesa OpenGL and Vulkan drivers for both 64-bit applications and Steam's 32-bit runtime. To use an integrated GPU on a Linux host, the host must expose `/dev/dri` to Docker. Uncomment the DRI device and group arguments in `devcontainer.json`, then rebuild the container. The `--group-add=109` argument assumes the host's render group is GID 109; replace it with the GID shown by `stat -c '%g' /dev/dri/renderD128` on the host if needed.

This passthrough is optional so the dev container still builds on hosts without a GPU. It cannot provide hardware acceleration when the host or its container runtime does not expose `/dev/dri` (including hosted environments without GPU passthrough).
