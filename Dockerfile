FROM alpine:3.21

RUN apk add --no-cache imagemagick libheif libjpeg-turbo perl-image-exiftool

# Alpine's perl-image-exiftool ships the module but not the CLI
RUN wget -qO /usr/local/bin/exiftool https://raw.githubusercontent.com/exiftool/exiftool/13.03/exiftool \
    && chmod +x /usr/local/bin/exiftool

WORKDIR /work
