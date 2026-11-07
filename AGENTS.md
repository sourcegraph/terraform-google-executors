# AGENTS.md

Guidance for coding agents working in this repository.

## What this is

A Terraform module that provisions [Sourcegraph executor](https://sourcegraph.com/docs/admin/executors) compute resources on Google Cloud (GCP). The repository root is itself a Terraform root module combining the submodules in `modules/`.

## Layout

- `main.tf`, `variables.tf`, `providers.tf` — the root module wiring together networking, docker-mirror, and executors.
- `modules/` — submodules, each self-contained (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `README.md`):
  - `networking/` — shared network/subnet (and optional NAT).
  - `docker-mirror/` — Docker registry pull-through cache.
  - `executors/` — executor compute resources and autoscaling.
  - `credentials/` — credentials for observability/auto-scaling from the Sourcegraph instance.
- `examples/` — `single-executor`, `private-single-executor`, `multiple-executors` usage examples.
- `.buildkite/` — CI scripts (the source of truth for the commands below).

## Toolchain

Tool versions are pinned in `.tool-versions` (managed via mise or asdf): Terraform `1.10.4`, `shfmt 3.2.0`, `shellcheck 0.10.0`, `github-cli 2.65.0`.

The module supports Terraform `>= 1.1.0, < 2.0.0` and the `hashicorp/google` provider `>= 5.0, < 8.0`.

## Common commands

These mirror the CI pipeline (`.buildkite/`); run them from the repository root.

```bash
# Format Terraform (CI checks with -check)
terraform fmt -recursive .

# Validate every module and example
.buildkite/terraform-validate.sh

# Shell script formatting and linting
shfmt -i 2 -ci -d .
shellcheck --external-sources --source-path=SCRIPTDIR $(find . -type f -name '*.sh')

# Security scan
.buildkite/ci-checkov.sh
```

Validation initializes and validates each of: `modules/networking`, `modules/docker-mirror`, `modules/executors`, `modules/credentials`, the root module, and all `examples/`.

## Conventions

- `.editorconfig` governs style: Terraform files use 2-space indent; shell scripts use 2-space indent with `switch_case_indent`; LF line endings and a trailing newline are required.
- Keep each submodule self-contained and surface new inputs/outputs through its `variables.tf`/`outputs.tf`.
- The major and minor version of this module must match the target Sourcegraph version (see `README.md`). Releases are driven by `release.yaml` and tracked in `CHANGELOG.md`.
