FROM alpine:3.21

RUN apk add --no-cache imagemagick libheif libjpeg-turbo

WORKDIR /work

ENTRYPOINT ["sh", "-c"]
