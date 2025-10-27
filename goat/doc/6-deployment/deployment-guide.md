# Deployment Guide

This document explains how to move GOAT from a packaged release into running infrastructure. It aligns with the packaging contract outlined in `packaging-guide.md` and highlights environment preparation, orchestration, and operational guardrails.

## Environments

- **Development**: ephemeral namespaces or containers spun up by individual engineers. Use the `latest` image tag, relaxed resource limits, and mocked integrations.
- **Staging**: long-lived environment that mirrors production topology. Only promote signed release tags here. Enable full integrations with sandbox credentials.
- **Production**: mission-critical footprint. Only deploy signed, SBOM-attached artifacts that passed staging validation.

Every promotion moves the same container image through the environment pipeline; never rebuild from source mid-way.

## Deployment architecture

- Target platform: Kubernetes (1.28+). A single deployment named `goat-api` runs multiple replicas behind a ClusterIP service.
- Backing services: managed PostgreSQL (15+) and Redis (7+) instances. Point the application to pre-provisioned instances; do not allow in-cluster stateful deployments.
- Networking: expose traffic through an ingress controller at `api.goat.example.com`. Enforce TLS everywhere.
- Storage: no persistent volumes required for the app, but attach a read-only ConfigMap for static templates if necessary.

## Required configuration

Populate the following environment variables (kubectl, Helm, or another mechanism) before applying manifests:

- `GOAT_DATABASE_DSN`
- `GOAT_REDIS_ADDR`
- `GOAT_ENV` (`staging` or `production`)
- `GOAT_JWT_SIGNING_KEY`
- `GOAT_WEBHOOK_SIGNING_SECRET`
- `GOAT_RATE_LIMIT_PROFILE`
- `GOAT_SAML_METADATA_URL` (optional; set when federation is enabled)

Mount secrets via your managed vault solution (e.g., AWS Secrets Manager, Vault, SOPS). Never bake them into images or ConfigMaps.

## Deploying with Helm (recommended)

Once the Helm chart is published, release using the following pattern:

```bash
CHART_VERSION=0.1.0
RELEASE_TAG=v2.1.0
NAMESPACE=goat-staging

helm upgrade --install goat-api charts/goat \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set image.repository=ghcr.io/your-org/goat \
  --set image.tag=$RELEASE_TAG \
  --set-file envSecrets=secrets/$NAMESPACE.env
```

The chart should template:

- A `Deployment` with configurable replica count (default 3 in production, 1 elsewhere).
- An `HorizontalPodAutoscaler` ranging from 3 to 12 replicas with CPU target 70%.
- A `Service` exposing port 8080 and optional `ServiceMonitor` for Prometheus scraping.

If Helm is unavailable, apply the rendered manifests stored under `dist/<version>/k8s/` that the packaging pipeline generated.

## Database migrations

Packaging ships migrations in `dist/<version>/migrations.tar.gz`. Apply them before flipping traffic:

1. Extract migrations to a jump box or admin pod.
2. Run `migrate -path ./migrations -database "$GOAT_DATABASE_DSN" up`.
3. Confirm the schema version matches `RELEASE_TAG` using `migrate version`.

For Kubernetes-native flows, add a pre-deploy `Job` that mounts the migrations archive and exits successfully before the main deployment is rolled out.

## Rollout process

1. Fetch the release bundle and verify signatures: `cosign verify` and SBOM diffing if required.
2. Apply configuration secrets (`kubectl apply -f secrets/<env>.yaml`).
3. Deploy via Helm or manifests.
4. Monitor rollout status: `kubectl rollout status deployment/goat-api -n <env>`.
5. Execute smoke tests from the staging harness (`go test ./test/e2e -tags=smoke`).
6. Flip traffic or update DNS only after smoke tests pass.

Use progressive delivery (canary or blue/green) in production when possible. At minimum, stage the new deployment behind a feature flag before exposing end users.

## Rollback

- Keep the previous release artifacts for at least 30 days.
- Roll back via Helm: `helm rollback goat-api <revision>`.
- Re-run migrations with the down script when available; otherwise, document manual remediation steps for irreversible schema changes before deploying.
- If data corruption is suspected, trigger database point-in-time recovery and invalidate any generated JWT signing keys.

## Observability and alerting

- **Logs**: stream to the central log stack (e.g., Elastic or Loki). Include trace IDs in structured JSON logs.
- **Metrics**: expose Prometheus metrics on `/metrics`. Track request latency, auth failures, and rate limiter throttles.
- **Tracing**: emit OpenTelemetry traces to the shared collector; ensure sampling is adjustable.
- **Alerts**: wire high-priority alerts for authentication failure spikes, latency > p95 500ms, and database connection saturation.

## Disaster readiness

- Schedule nightly database backups and validate restores weekly.
- Regularly rotate credentials (JWT signing keys, Redis passwords) and document the rotation runbook.
- Document dependency outages (email/SMS providers, identity bridges) with fallback plans.

Following this guide ensures the packaged GOAT release moves through environments predictably, with reproducible artifacts and auditable deployment steps.
