# img-tools

Docker-based ImageMagick + exiftool wrapper. Keeps heavy image tooling off
the host. Every script runs commands inside the `img-tools:latest` container
via a shared shell helper.

## Architecture

- `Dockerfile` — Alpine 3.21 + `imagemagick` + `libheif` + `libjpeg-turbo` +
  `perl-image-exiftool`. No `ENTRYPOINT`; commands are passed in directly.
- `lib/img-docker` — sourced by every script. Builds the image on first use
  and exposes:
  - `img_run [--mount DIR]... CMD [ARG...]` — run a command in the container
  - `img_mount_for PATH` — print the host directory that must be mounted to
    expose PATH inside the container (directories mount themselves; files
    mount their parent)
  - `img_abs_path PATH` — canonicalize a path to absolute form
- Use-case scripts at repo root call `img_run` with one or more `--mount`
  flags per input path.
- `work/` — gitignored scratch directory for inputs. Only `work/.gitkeep` is
  tracked.
- `tmp/` — gitignored scratch for ephemeral files (e.g. PR/issue bodies).
- Image name: `img-tools:latest`.

## Bind-mount strategy

`img_run` always mounts the host cwd at its real path inside the container
(so relative paths just work). Each `--mount HOSTDIR` option adds another
host directory bound at the same path inside the container. Scripts compute
the mount for each input path via `img_mount_for`:

- Directory inputs mount themselves
- File inputs mount their parent directory

This means scripts work with relative paths, absolute paths, and `~/...`
paths transparently. Mounts already covered by the cwd mount are skipped;
duplicate mounts are deduped; the host root `/` is never mounted (Docker
rejects it and it's a security footgun).

When adding a new script, compute `img_mount_for` once per input path and
pass it via `--mount` to every `img_run` call that touches that path.

The cost: the container sees everything in the mounted directories. Document
this for users; the README has the standard wording.

Spaces in paths are not handled by the mount-args word-splitting in
`img_run`. Don't introduce paths with spaces.

## Script conventions

Every script at the repo root follows the same shape:

```sh
#!/bin/sh
set -eu

case "$0" in
  /*) repo_dir="$(dirname "$0")" ;;
  */*) repo_dir="$(cd "$(dirname "$0")" && pwd)" ;;
  *) repo_dir="$(dirname "$(command -v "$0")")" ;;
esac
. "$repo_dir/lib/img-docker"

usage() {
  cat <<EOF
Usage: $(basename "$0") ...
EOF
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  '') usage >&2; exit 1 ;;
esac

# ... script body, calling img_run with --mount ...
```

The three-arm `case` resolves `repo_dir` whether the script was invoked by
absolute path, relative path, or via `PATH`. Keep this block intact.

Every script supports `-h` and `--help`. The `usage` heredoc prints the
synopsis, arguments, options, and any environment variables. Errors send
usage to stderr (`usage >&2; exit 1`); help goes to stdout (`exit 0`).

### Naming

- `<src>-to-<dst>` (e.g. `heic-to-jpg`, `png-to-jpg`, `jpeg-to-jpg`):
  per-type conversion. Accepts files or directories. With `-r`, recurses.
  Writes a sibling output; source is left in place. Non-matching files are
  silently skipped (so dispatchers can safely fan out the same args).
- `convert`: thin dispatcher that runs every `*-to-jpg` script in sequence
  on the same args. No `lib/img-docker` source — it just shells out.
- `resize`: file arguments, writes `<name>-resized.<ext>` siblings.
- `identify`: pass-through to ImageMagick's `identify`.
- `images-*`: takes a directory argument, processes matching files in
  place (destructive).

### Directory walk pattern

The conversion scripts use a recursive function with this exact shape:

```sh
fn_process() {
  p="$1"
  if test -d "$p"; then
    for f in "${p%/}"/*; do
      if test -d "$f" && test "$recursive" -eq 1; then
        fn_process "$f"
      elif test -f "$f"; then
        case "$f" in
          MATCH_PATTERNS) fn_convert "$f" ;;
        esac
      fi
    done
  elif test -f "$p"; then
    case "$p" in
      MATCH_PATTERNS) fn_convert "$p" ;;
    esac
  fi
}
```

Note the recursion guard is `test -d "$f" && test "$recursive" -eq 1` as
the `if` condition — not `test -d "$f"; then test ... && fn_process`. The
latter shape triggers `set -e` exit when `recursive=0` because the final
`test 0 -eq 1` returns non-zero outside an `if` context. Mirror the
existing pattern when adding a new conversion script.

### POSIX shell

Follow `skill:shell-scripting`. `#!/bin/sh`, `set -eu`, lowercase variables,
`fn_` prefix on local functions, `test` instead of `[ ]`, no bashisms.

## Destructive-by-design policy

`images-auto-orient` and `images-remove-meta` modify files in place and do
not back up. There is no `-d` / dry-run flag; do not add one. Rationale:
callers are expected to keep originals outside the workspace (see `work/`
convention), dry-run gave a false sense of safety, and the conditional
branches added noise. If a future operation truly needs preview, prefer a
separate read-only script (`identify`-style) over reintroducing dry-run.

The `*-to-jpg` scripts and `resize` are non-destructive: they add a new
file next to the source and leave the original intact.

## Quality knob

When re-encoding JPEGs, read `IMG_JPG_QUALITY` with a default of 85. This
is the existing pattern in every script that writes JPEGs.

## Gotchas

- Alpine's default `imagemagick` package does not include HEIC delegates —
  `libheif` must be in the Dockerfile
- Alpine's default `imagemagick` package does not include JPEG write
  support — `libjpeg-turbo` must be in the Dockerfile (pulls in
  `imagemagick-jpeg`). Without it, `magick` will silently write HEIC data
  to `.jpg` files instead of re-encoding
- No `ENTRYPOINT` in the Dockerfile — commands are passed directly via
  `docker run`. `img_run` relies on this
- `images-remove-meta` uses `exiftool`. Alpine's `perl-image-exiftool`
  ships only the Perl module, not the CLI. The Dockerfile downloads the
  CLI script from the exiftool GitHub repo at build time (version 13.03).
  That version must match the Alpine package version when it gets bumped
- `images-remove-meta` behaves differently per format: JPG gets
  `-Orientation=` (narrow, matches `images-auto-orient`), PNG gets `-all=`
  (broad — needed to scrub tEXt/iTXt/XMP chunks where tools like Midjourney
  embed job IDs, prompts, and IPTC `DigitalSourceType`). If you extend to
  a new format, decide deliberately which behavior fits
- `mogrify -format jpg FILE` writes a sibling `FILE.jpg` and does NOT
  delete `FILE`. The `*-to-jpg` scripts rely on this — conversion is
  additive, not destructive

## Pre-commit

- Dockerfile must build cleanly: `docker build -t img-tools .`
- Smoke test from a fresh clone: `./identify <some_image>` should build
  the image and print info
- `shellcheck` and `shfmt` on any changed scripts
