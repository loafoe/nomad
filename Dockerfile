FROM alpine:latest AS builder
ENV NOMAD_VERSION 1.2.2


WORKDIR /nomad
RUN apk add --no-cache git openssh gcc musl-dev curl gnupg unzip

# Download Nomad and verify checksums (https://www.hashicorp.com/security.html)
COPY resources/hashicorp.asc /tmp/
# Fix exec permissions issue that come up due to the way source controls deal with executable files.
RUN gpg --import /tmp/hashicorp.asc
RUN curl -Os https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
RUN curl -Os https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS
RUN curl -Os https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig

# Verify the signature file is untampered.
RUN gpg --verify nomad_${NOMAD_VERSION}_SHA256SUMS.sig nomad_${NOMAD_VERSION}_SHA256SUMS
# The checksum file has all platforms, we are interested in only linux x64, so only check that one.
RUN grep -E '_linux_amd64' < nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c
RUN unzip nomad_${NOMAD_VERSION}_linux_amd64.zip

FROM ubuntu:latest 
LABEL maintainer="Andy Lo-A-Foe <andy.lo-a-foe@philips.com>"

WORKDIR /app
COPY --from=builder /nomad/nomad /usr/local/bin/nomad
EXPOSE 4646
CMD ["/usr/local/bin/nomad"]
