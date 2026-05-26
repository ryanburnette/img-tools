FROM alpine:3.21

RUN apk add --no-cache imagemagick libheif

WORKDIR /work

ENTRYPOINT ["sh", "-c"]
