# Template

# Development and Publishing

## Running GUI apps in the dev container

The container is set up to render SDL3 windows onto the host desktop, with
hardware acceleration via `/dev/dri`.

### Host prerequisites

Before opening the container, these must be present in the environment of
whatever launches it (VS Code or the `devcontainer` CLI):

| Variable | Example | Purpose |
| --- | --- | --- |
| `TLT_DEVCONTAINER_TARGET` | `archlinux-withdeps` | Dockerfile stage to build |
| `XDG_RUNTIME_DIR` | `/run/user/1000` | host dir holding the wayland socket |
| `WAYLAND_DISPLAY` | `wayland-1` | wayland socket name |
| `DISPLAY` | `:1` | X11/Xwayland display, used for the fallback |

### Container user

The container runs as **root** by default, which is why no group membership is
needed for `/dev/dri` or the wayland socket — root bypasses those permission
checks. The trade-off: everything written to the bind-mounted workspace is
root-owned on the host, `.build/` included. Clear it with `sudo rm -rf .build`
when you need to touch it from outside the container.

A non-root `dev` user is also built into the image as an opt-in alternative that
avoids that. Its uid/gid and GPU group memberships are `ARG` defaults in
[docker/Dockerfile.ArchLinux](docker/Dockerfile.ArchLinux) — match them to your
host before using it:

```sh
id                          # -> USER_UID / USER_GID
getent group render video   # -> RENDER_GID / VIDEO_GID
```

Then either `su - dev` inside the container, or uncomment `"remoteUser": "dev"`
in [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json). Wrong
uid/gid there means a permission error on `/dev/dri`.

### Verifying inside the container

```sh
ls -l /dev/dri                       # cardN + renderDN present
ls -l "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
pacman -S --noconfirm mesa-utils vulkan-tools
glxinfo -B                           # renderer should NOT be llvmpipe
vulkaninfo --summary
```

Then build with the presets in [CMakePresets.json](CMakePresets.json) and run
the `example` binary — a decorated, input-responsive window should appear.

### Backend overrides

`SDL_VIDEODRIVER` is intentionally left unset so SDL autodetects wayland and
falls back to x11. To force one:

```sh
SDL_VIDEODRIVER=x11 ./example        # via Xwayland on $DISPLAY
SDL_VIDEODRIVER=wayland ./example
LIBGL_ALWAYS_SOFTWARE=1 ./example    # software rendering (no /dev/dri needed)
```

**The x11 backend does not work as root.** If the host X server has no
`~/.Xauthority` and relies on uid-based local auth — check with `xhost`, which
then prints a lone `SI:localuser:<you>` — only that uid may connect, and root
fails with `Authorization required, but no authorization protocol specified`.
Wayland is unaffected: it authorizes by socket permissions, which root bypasses.

To use the x11 backend, pick one:

- run as the `dev` user, whose uid matches the host and is therefore authorized;
- or grant root access from the host once per session:
  `xhost +si:localuser:root` (loosens X access control).

For headless or SSH use, drop the wayland mount and rely on x11 forwarding: keep
the `/tmp/.X11-unix` mount, set `DISPLAY`, and export `SDL_VIDEODRIVER=x11` —
this path does provide an `.Xauthority` cookie, so root works there.
