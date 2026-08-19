# Cloudflare Workers

This directory contains edge services deployed independently from the Kubernetes
cluster. Each Worker owns its Wrangler configuration, dependencies, tests, and
operational documentation.

Workers are not reconciled by Argo CD. Deploy them explicitly from their own
directory after reviewing the configured Cloudflare routes and secrets.

- [`kms`](kms/) provides the minimal Vault Transit-compatible service used for
  Vault auto-unseal.
