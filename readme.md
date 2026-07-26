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

## CI

[.github/workflows/devcontainer-build.yml](.github/workflows/devcontainer-build.yml)
builds the project on push/PR to `main` (and via *Run workflow*) using
[devcontainers/ci](https://github.com/devcontainers/ci), so CI compiles inside
the very same image as local development — one toolchain definition,
[docker/Dockerfile.ArchLinux](docker/Dockerfile.ArchLinux), instead of a
parallel `apt install` list in the workflow.

### Flavors

| Axis | Values | Maps to |
| --- | --- | --- |
| `platform` | `linux` | second half of the preset name |
| `compiler` | `clang`, `gcc` | first half of the preset name |
| `deps` | `withdeps`, `nodeps` | Dockerfile stage `archlinux-<deps>` |
| `build_type` | `Debug`, `Release` | `--config` of the multi-config build |

`platform` + `compiler` are exactly the preset naming scheme
(`<compiler>-<platform>` in [CMakePresets.json](CMakePresets.json)), so adding a
platform means adding a toolchain file and a preset, then one matrix entry — the
workflow needs no other change. Windows and Android cross-compile from the same
Linux container and are sketched as commented `include:` entries. macOS is the
exception: a Linux dev container does not run on a macos runner, so it needs a
separate non-containerized job.

`deps` selects where SDL3 comes from: `withdeps` uses the pacman package,
`nodeps` has CPM build it from source (`CPM_USE_LOCAL_PACKAGES` finds nothing
there). That is why the CI config keeps `${localEnv:TLT_DEVCONTAINER_TARGET}`
just like the local one — the workflow sets it per matrix entry.

### Pipeline

Two stages, so the image is built once instead of once per build:

1. `image` — [devcontainers/ci](https://github.com/devcontainers/ci) builds the
   dev container and publishes it to GHCR as
   `ghcr.io/<owner>/<repo>/devcontainer:<tag>-<deps>`. `runCmd` is deliberately
   omitted, which turns the action into a pure prebuild step. One job per
   dependency flavor; both compilers live inside each image.
2. `build` — the matrix of actual builds, running *inside* that published image
   via `jobs.<id>.container`. No devcontainer tooling on this stage: GitHub
   pulls the image and runs the steps in it, so the steps are plain `cmake`
   invocations.

Tags are `<ref>-archlinux-<deps>`, where `<ref>` is `main` for pushes and
`pr-<number>` for pull requests — so a PR touching the Dockerfile cannot poison
the image `main` builds against. Each build reuses `main-archlinux-<deps>` as
its layer cache (`cacheFrom`), so a PR that does not touch the Dockerfile pays
almost nothing; a fresh repository has no cache and simply builds from scratch.

The flavor half of the tag is the Dockerfile stage verbatim, which is what lets
a local checkout name the image with nothing but `TLT_DEVCONTAINER_TARGET` (see
below).

PR tags are deleted by
[.github/workflows/devcontainer-cleanup.yml](.github/workflows/devcontainer-cleanup.yml)
when the pull request closes; its `workflow_dispatch` trigger takes a PR number
for tags left behind by a run that died early. It deletes a package version only
when *every* tag on it belongs to that PR — an image identical to main's shares
its digest, and therefore its version, and a blind delete would take main's tag
down with it.

`containerEnv` from `devcontainer.json` does **not** apply to stage 2 (GitHub
does not read that file), so `CPM_SOURCE_CACHE` is set again in the job `env`;
CPM downloads are cached via `actions/cache` → `.cpm-cache/`.

Stage 1 needs `packages: write`, stage 2 only `packages: read`. **Pull requests
from forks will fail here**: their `GITHUB_TOKEN` cannot push to GHCR, so there
is no image for stage 2. If this template ever takes fork PRs, that case needs a
fallback that builds and runs in one job with `push: never`.

### Using the CI image locally

[.devcontainer/devcontainer.json](.devcontainer/devcontainer.json) points
`build.cacheFrom` at `main-${localEnv:TLT_DEVCONTAINER_TARGET}`, so opening the
container pulls the image CI published for that stage and reuses its layers
instead of running `pacman` locally. The Dockerfile stays the source of truth —
this only replaces the *work*, not the definition — and any miss (offline, not
logged in, locally edited Dockerfile) just falls back to a normal local build.

While the package is private, docker needs credentials for the pull:

```sh
# classic PAT with read:packages
echo "$GHCR_TOKEN" | docker login ghcr.io -u <your-github-user> --password-stdin
```

Making the package public in *Packages → Package settings* removes that step.
To warm the cache up front, or to inspect the exact image CI used:

```sh
docker pull ghcr.io/ygrik2003/cxx_project_template/devcontainer:main-archlinux-withdeps
```

Layer reuse assumes an unmodified Dockerfile *and* the `ARG` defaults CI built
with — a different `USER_UID`/`USER_GID` invalidates everything from `useradd`
onward, though the pacman layers above it still hit.

### Other notes

The build is the same two commands you would run by hand:

```sh
cmake --preset clang-linux
cmake --build .build/clang-linux --config Debug
```

The `example` binary is not executed in CI — it opens an SDL3 window and the
runner has no display.
