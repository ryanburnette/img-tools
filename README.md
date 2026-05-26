# img-tools

Docker-based image tools. No ImageMagick installed on the host.

## Setup

Symlink the scripts you want into your PATH:

```sh
ln -s /path/to/img-tools/heic-to-jpg ~/.local/bin/heic-to-jpg
ln -s /path/to/img-tools/resize ~/.local/bin/resize
ln -s /path/to/img-tools/identify ~/.local/bin/identify
```

Or run them directly from the repo: `./heic-to-jpg *.HEIC`

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

## Rebuilding

The Docker image builds automatically on first run. To rebuild after Dockerfile changes:

```sh
docker build -t img-tools .
```
