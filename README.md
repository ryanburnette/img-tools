# img-tools

Docker-based image tools. No ImageMagick or exiftool installed on the host —
everything runs inside a small Alpine container that builds on first use.

## Requirements

- Docker (Desktop on macOS, engine on Linux)
- `git` to clone the repo

The Docker image (`img-tools:latest`) builds automatically the first time you
run any script. Rebuild manually after editing the Dockerfile:

```sh
docker build -t img-tools .
```

## Setup

Add the repo directory to your `PATH`.

Conventional shell:

```sh
export PATH="/path/to/img-tools:$PATH"
```

For [pathman](https://webinstall.dev/pathman) users:

```sh
pathman add /path/to/img-tools
```

Then run any script from anywhere:

```sh
heic-to-jpg *.HEIC
resize 800 *.jpg
convert ~/Downloads
```

Or run directly from the repo: `./heic-to-jpg *.HEIC`.

Every script accepts `-h` / `--help` and prints usage.

## How paths work

Each script mounts the directories containing your input paths into the
container so the tools inside (`magick`, `exiftool`, `mogrify`, `identify`)
can read and write them. Relative paths, absolute paths, and `~/...` paths
all work — the script picks the right directories to mount based on what
you pass in.

### Security note

The container sees the contents of your **current working directory** and
the **parent directories of any path arguments you pass**. Don't run these
tools from a directory whose contents you'd rather not expose, and don't
pass paths into directories you don't want the container to read or modify.

## Working directory

The `work/` directory is gitignored. Drop images there for processing so
nothing in your camera roll or source folders gets touched:

```sh
cp ~/photos/*.HEIC work/
convert work/
```

## Safety

`images-auto-orient` and `images-remove-meta` rewrite files in place — no
dry-run, no backup. Always have the originals backed up somewhere outside
this workspace before running them.

The other scripts (`heic-to-jpg`, `png-to-jpg`, `jpeg-to-jpg`, `convert`,
`resize`) write new files alongside the input and never overwrite or remove
the source.

## Scripts

### `heic-to-jpg`, `png-to-jpg`, `jpeg-to-jpg`

Convert files of a specific source type to JPEG. Each PATH can be a file or
a directory; with `-r`, directories are walked recursively. The source is
left in place and a sibling `.jpg` is written. Files of other types are
silently skipped, so it's safe to call against a mixed directory.

```sh
heic-to-jpg IMG_0001.HEIC IMG_0002.HEIC
heic-to-jpg ~/Downloads/*.HEIC
heic-to-jpg work/

png-to-jpg ~/exports/
png-to-jpg -r work/

jpeg-to-jpg dropbox/*.jpeg          # normalize .jpe / .jpeg to .jpg

IMG_JPG_QUALITY=92 heic-to-jpg *.HEIC
```

- Auto-orients during conversion
- Quality 85 (override with `IMG_JPG_QUALITY`)
- Supported source extensions (case-insensitive):
  - `heic-to-jpg`: `.heic`
  - `png-to-jpg`: `.png`
  - `jpeg-to-jpg`: `.jpe`, `.jpeg`

### `convert`

Dispatcher that runs `heic-to-jpg`, `png-to-jpg`, and `jpeg-to-jpg` in
sequence on the same `[-r] PATH...` arguments. Handy when you have a
mixed directory and just want everything turned into JPGs.

```sh
convert work/
convert -r ~/Downloads
convert /tmp/photos/foo.HEIC /tmp/photos/bar.png
```

### `resize`

Resize images, writing each output as `<name>-resized.<ext>`. Shrink-only:
images smaller than the target are passed through without resampling.

```sh
resize 600 photo.jpg          # max 600px on the long edge
resize photo.jpg              # default 1200px
resize 1080 work/*.jpg
IMG_JPG_QUALITY=92 resize 800 *.jpg
```

- Auto-orients based on EXIF
- Quality 85 (override with `IMG_JPG_QUALITY`)

### `identify`

Print image info. Pass-through to ImageMagick's `identify`.

```sh
identify photo.jpg
identify -verbose photo.png       # full metadata dump
```

Use `identify -verbose` to see EXIF, IPTC, XMP, and PNG text chunks —
useful for confirming what metadata is embedded before stripping.

### `images-auto-orient`

Apply EXIF orientation to every `.jpg` in a directory, rotating pixels so
the image is visually upright and clearing the orientation tag. Modifies
files in place.

```sh
images-auto-orient work/photos
images-auto-orient ~/photos/trip
```

### `images-remove-meta`

Strip embedded metadata from `.jpg` and `.png` files in a directory.
Modifies files in place.

```sh
images-remove-meta work/photos
images-remove-meta ~/exports
```

- JPG: clears `Orientation` only (pairs with `images-auto-orient`)
- PNG: strips all metadata (`exiftool -all=`), including tEXt/iTXt chunks
  and XMP. Useful for scrubbing AI-generation tags (Midjourney job IDs,
  IPTC `DigitalSourceType`, author, prompt) from PNG exports
