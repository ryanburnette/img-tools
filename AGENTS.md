# img-tools

Docker-based ImageMagick wrapper. Keeps heavy image tools off the host machine.

## Architecture

- `Dockerfile` — Alpine 3.21 + `imagemagick` + `libheif` + `libjpeg-turbo`
- `lib/img-docker` — shared Docker helper (build image, run commands)
- Use-case scripts at repo root call `img_run` from `lib/img-docker`
- Image name: `img-tools:latest`

## Adding a new script

1. Create an executable at repo root
2. Source `lib/img-docker`: `. "$(dirname "$0")/lib/img-docker"`
3. Call `img_run <command> [args...]`
4. The Docker image has no `ENTRYPOINT` — `img_run` passes the command and args directly

## Gotchas

- Alpine's default `imagemagick` package does not include HEIC delegates — `libheif` must be in the Dockerfile
- Alpine's default `imagemagick` package does not include JPEG write support — `libjpeg-turbo` must be in the Dockerfile (pulls in `imagemagick-jpeg`)
- Without `libjpeg-turbo`, `magick` will silently write HEIC data to `.jpg` files instead of re-encoding as JPEG
- No `ENTRYPOINT` in the Dockerfile — commands are passed directly via `docker run`

## Pre-commit

- Dockerfile must build cleanly: `docker build -t img-tools .`
- Test with: `./identify <some_image>`
