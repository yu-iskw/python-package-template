# 2. Mise toolchain and attestation settings

Date: 2026-05-23

## Status

Accepted

## Context

The template pins CLI tools (Trunk, Trivy, OSV-Scanner, Grype, CodeQL) with [mise](https://mise.jdx.dev/) using `mise.toml`, `[tasks]`, and a committed `mise.lock`. Releases are gated with `minimum_release_age = "7d"`.

In some environments (restricted CI, air-gapped networks), Sigstore/TUF and GitHub artifact attestation endpoints are unreachable. Mise can verify downloads with cosign, SLSA, and GitHub attestations when those services are available.

## Decision

1. **Invoke tools via mise tasks only** — `mise run <task>` or Makefile targets that delegate to `mise run`. Do not add shell wrapper scripts (e.g. `mise-exec.sh`) to call `mise exec`.
2. **Disable remote attestation checks in `mise.toml`** when the network cannot reach them:
   - `[settings.aqua]` `cosign = false`, `slsa = false`
   - `[settings.github]` `github_attestations = false`
3. **Rely on `mise.lock` checksums** for reproducible installs (`mise install --locked`).
4. **Re-enable attestation** in `mise.toml` when the environment supports Sigstore/TUF and GitHub attestations.

## Consequences

- Installs remain pinned and reproducible via `mise.lock` without live attestation API calls.
- Teams on fully connected networks should consider re-enabling attestation for defense in depth.
- CI validates the toolchain in `.github/workflows/mise_toolchain.yml` using `jdx/mise-action`.
