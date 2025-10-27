# Packaging Guide

This guide defines how we produce distributable artifacts for GOAT. It covers versioning, binary builds, container images, and supporting bundles that downstream deployment automation expects.

## Scope and assumptions

- Source code lives under `src/main`. Domain modules are kept in `src/main/internal`, migrations in `src/main/migrations`.
- The runnable entry point will eventually live in `src/main/cmd/goat` (or a similarly named binary directory). Until that arrives, treat the packaging steps that require a binary as **pending**.
- All commands assume execution from the repository root unless stated otherwise.

## Release checklist

Before packaging anything:

1. Ensure the branch is tagged or otherwise versioned (semantic versioning preferred, for example `v2.1.0`).
2. From `src/main`, run the full test suite: `CGO_ENABLED=0 go test ./...`.
3. Still under `src/main`, vet the migration package: `go vet ./migrations/...`, then dry-run them against a staging database.
4. Update user-facing docs and the changelog/roadmap as required.

Only start packaging after the checklist is green.

## Version stamping

We inject the release version into the binary at build time using `-ldflags`. When the entry point becomes available, add a `Version` variable to the `main` package so that:

```bash
CGO_ENABLED=0 GOOS=$GOOS GOARCH=$GOARCH go build \
  -ldflags "-s -w -X main.Version=$RELEASE" \
  -o dist/$RELEASE/$GOOS-$GOARCH/goat \
  ./cmd/goat
```

Recommended target matrix:

- `linux/amd64`
- `linux/arm64`
- `darwin/arm64`
- `windows/amd64`

Store the binaries under `dist/<version>/<os>-<arch>/` so downstream automation can pick them up consistently.

## Container image

Plan to maintain a `build/Dockerfile` template with the following characteristics once the binary package exists:

```Dockerfile
# syntax=docker/dockerfile:1.6
FROM golang:1.22-alpine AS build
WORKDIR /src
COPY src/main/ ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w" -o /out/goat ./cmd/goat

FROM gcr.io/distroless/base-debian12
WORKDIR /app
COPY --from=build /out/goat ./goat
COPY src/main/migrations ./migrations
ENTRYPOINT ["/app/goat"]
```

Key expectations:

- The resulting image must remain under 100MB compressed.
- Include SQL migrations alongside the binary; the service applies pending migrations on startup.
- Expose port `8080` by default and read configuration strictly from environment variables.

Build and tag the image during packaging:

```bash
REGISTRY=ghcr.io/your-org
RELEASE=v2.1.0

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t "$REGISTRY/goat:$RELEASE" \
  -t "$REGISTRY/goat:latest" \
  -f build/Dockerfile .

docker push "$REGISTRY/goat:$RELEASE"
docker push "$REGISTRY/goat:latest"
```

## SBOM and signatures

We require a software bill of materials (SBOM) for every release:

```bash
syft "$REGISTRY/goat:$RELEASE" -o spdx-json > dist/$RELEASE/sbom.spdx.json
cosign sign --key cosign.key "$REGISTRY/goat:$RELEASE"
```

Store generated SBOMs and signatures alongside binaries under `dist/<version>/` and attach them to the GitHub release.

## Ancillary bundles

- **Configuration templates**: once they exist, keep environment-specific examples under `deploy/config/<env>/app.env.example` and ship them with the release bundle.
- **Migrations archive**: package `src/main/migrations` into `dist/<version>/migrations.tar.gz` so operators can run migrations out of band.
- **Helm chart (when ready)**: publish chart packages to the internal chart repository and cross-link them from the release notes.

## Pulling it together

A full packaging run (triggered from CI) should:

1. Fetch dependencies and run tests.
2. Build multi-platform binaries.
3. Build and push the container image.
4. Generate SBOM + signatures.
5. Archive migrations and configuration templates.
6. Create a Git tag and GitHub release with all artifacts attached.

Until the entry point is merged, CI can still exercise the test + archive steps to keep the pipeline green. Once the binary directory lands, enable the build and image steps without changing the documented interface.
