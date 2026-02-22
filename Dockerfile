# syntax=docker/dockerfile:1

# ---- Build stage ----
FROM golang:1.25-alpine AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ARG VERSION=dev

RUN CGO_ENABLED=0 go build \
    -ldflags="-s -w -X main.version=${VERSION}" \
    -o /claws ./cmd/claws

# ---- Runtime stage ----
FROM alpine:3.21

# CA certs for AWS API TLS, and tzdata for time zone support
RUN apk add --no-cache ca-certificates tzdata

COPY --from=build /claws /usr/local/bin/claws

RUN adduser -D -h /home/claws claws
USER claws
WORKDIR /home/claws

ENTRYPOINT ["claws"]
