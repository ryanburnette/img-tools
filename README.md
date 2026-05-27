# img-tools

Docker-based image tools. No ImageMagick or exiftool installed on the host.

## Setup

Symlink the scripts you want into your PATH:

```sh
ln -s /path/to/img-tools/heic-to-jpg ~/.local/bin/heic-to-jpg
ln -s /path/to/img-tools/resize ~/.local/bin/resize
ln -s /path/to/img-tools/identify ~/.local/bin/identify
ln -s /path/to/img-tools/images-auto-orient ~/.local/bin/images-auto-orient
ln -s /path/to/img-tools/images-remove-meta ~/.local/bin/images-remove-meta
ln -s /path/to/img-tools/images-to-jpg ~/.local/bin/images-to-jpg
```

Or add the repo directory to your PATH: `export PATH="/path/to/img-tools:$PATH"`

Or run them directly from the repo: `./heic-to-jpg *.HEIC`

> **Note on symlinks:** The scripts resolve `lib/img-docker` relative to their own location via `$0`. Symlinks currently break this resolution (e.g., `dirname "$0"` returns the symlink's directory, not the repo). If you symlink into PATH, use absolute symlinks: `ln -s /absolute/path/to/img-tools/identify ~/.local/bin/identify`. Adding the repo directory to PATH is simpler and avoids this issue entirely.

## Working directory

The `work/` directory is gitignored. Put images there for processing:

```sh
cp ~/photos/*.HEIC work/
./images-to-jpg work/
```

## Scripts

### `heic-to-jpg`

Convert HEIC files to JPEG with resize. Reasonable defaults.

```sh
heic-to-jpg IMG_0001.HEIC IMG_0002.HEIC
```

- Resizes to 1200px long edge
- Quality 85
- Output: `IMG_0001.jpg`, `IMG_0002.jpg`
- Override defaults with env vars: `IMG_MAX_PX=800 IMG_JPG_QUALITY=90 heic-to-jpg *.HEIC`

### `resize`

Resize images. Outputs as `<name>-resized.<ext>`.

```sh
resize 600 photo.jpg          # max 600px
resize photo.jpg              # default 1200px
```

### `identify`

Get image info.

```sh
identify photo.jpg
```

### `images-auto-orient`

Fix EXIF orientation on JPGs in a directory. Modifies files in place.

```sh
images-auto-orient work/photos       # process all .jpg files
images-auto-orient -d work/photos    # dry run
```

### `images-remove-meta`

Strip orientation metadata from JPGs in a directory. Modifies files in place.

```sh
images-remove-meta work/photos       # strip metadata
images-remove-meta -d work/photos    # dry run
```

### `images-to-jpg`

Convert HEIC/PNG/JPEG files to JPG in a directory.

```sh
images-to-jpg work/photos            # convert supported files
images-to-jpg -r work/photos         # recursive
images-to-jpg -d work/photos         # dry run
```

- Auto-orients during conversion
- Skips files already in JPG format
- Supports: HEIC, PNG, JPE, JPEG

## Rebuilding

The Docker image builds automatically on first run. To rebuild after Dockerfile changes:

```sh
docker build -t img-tools .
```
