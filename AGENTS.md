# img-tools

Docker-based ImageMagick wrapper. Keeps heavy image tools off the host machine.

## Architecture

- `Dockerfile` — Alpine 3.21 + `imagemagick` + `libheif` + `libjpeg-turbo` + `perl-image-exiftool`
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
- `images-remove-meta` uses `exiftool` — Alpine's `perl-image-exiftool` ships only the Perl module, not the CLI. The Dockerfile downloads the CLI script from the exiftool GitHub repo at build time. The version (13.03) must match the Alpine package version.
- `images-remove-meta` behaves differently per format: JPG gets `-Orientation=` (narrow, matches `images-auto-orient`), PNG gets `-all=` (broad — needed to scrub tEXt/iTXt/XMP chunks where tools like Midjourney embed job IDs, prompts, and IPTC `DigitalSourceType`). If you extend to a new format, decide deliberately which behavior fits.
- The `work/` directory is gitignored — put images there for processing
- Directory-based scripts (`images-*`) take a directory argument and process files in place

## Pre-commit

- Dockerfile must build cleanly: `docker build -t img-tools .`
- Test with: `./identify <some_image>`
