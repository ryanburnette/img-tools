# img-tools

Run ImageMagick tools (convert, mogrify, identify, etc.) via Docker — no local install needed.

## Setup

Add the wrapper script to your PATH:

```sh
ln -s /path/to/img-tools/img-tools ~/.local/bin/img-tools
```

Or call it directly: `./img-tools "<command>"`

## Usage

The wrapper mounts your current working directory at `/work` inside the container. Any command runs as if the tool were installed locally.

```sh
# Identify an image
img-tools "identify photo.jpg"

# Convert formats (use `magick` in IMv7)
img-tools "magick input.png output.webp"

# Convert HEIC to JPG
img-tools "magick IMG_0001.HEIC IMG_0001.jpg"

# Batch resize with mogrify
img-tools "mogrify -resize 50% *.jpg"

# Get image dimensions
img-tools "identify -format '%wx%h' image.png"
```

## Rebuilding

The image builds automatically on first run. To rebuild after changes:

```sh
docker build -t img-tools .
```
