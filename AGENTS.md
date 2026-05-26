# img-tools

Docker-based ImageMagick wrapper. Keeps heavy image tools off the host machine.

## Architecture

- `Dockerfile` — Alpine 3.21 + `imagemagick` + `libheif` (for HEIC support)
- `img-tools` — Shell wrapper: auto-builds the image, mounts `$(pwd)` at `/work`, passes the command through
- Image name: `img-tools:latest`

## Usage

```sh
img-tools "<imagemagick command>"
```

The wrapper mounts the current working directory at `/work` inside the container. Commands run as if the tools were installed locally.

## Commands

- Use `magick` instead of `convert` (IMv7 deprecation)
- `mogrify` for in-place batch ops
- `identify` for image info
- HEIC/HEIF supported out of the box

## Gotchas

- Alpine's default `imagemagick` package does not include HEIC delegates — `libheif` must be in the Dockerfile
- The `img-tools` script passes the entire argument string via `sh -c`, so quote the command as one string
- Image auto-builds on first run (silently). Rebuild manually after Dockerfile changes: `docker build -t img-tools .`

## Pre-commit

- Dockerfile must build cleanly: `docker build -t img-tools .`
- Test with: `img-tools "identify -version"`
