# img-tools

Docker-based image tools. No ImageMagick or exiftool installed on the host.

## Setup

Add the repo directory to your PATH:

```sh
export PATH="/path/to/img-tools:$PATH"
```

Or run scripts directly from the repo: `./heic-to-jpg *.HEIC`

## Working directory

The `work/` directory is gitignored. Put images there for processing:

```sh
cp ~/photos/*.HEIC work/
./images-to-jpg work/
```

## Scripts

### `heic-to-jpg`

Convert HEIC files to JPEG. No resizing (use `resize` for that).

```sh
heic-to-jpg IMG_0001.HEIC IMG_0002.HEIC
```

- Auto-orients based on EXIF
- Quality 85
- Output: `IMG_0001.jpg`, `IMG_0002.jpg`
- Override quality with env var: `IMG_JPG_QUALITY=90 heic-to-jpg *.HEIC`

### `resize`

Resize images. Outputs as `<name>-resized.<ext>`.

```sh
resize 600 photo.jpg          # max 600px
resize photo.jpg              # default 1200px
```

- Shrink-only: images smaller than the target are left untouched
- Auto-orients based on EXIF
- Quality 85
- Override quality with env var: `IMG_JPG_QUALITY=90 resize 800 *.jpg`

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
