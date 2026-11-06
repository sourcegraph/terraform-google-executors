<!-- README:
Use `**BREAKING**:` to denote a breaking change
-->

# Changelog

<!-- START CHANGELOG -->

## Unreleased

### Added

- `sourcegraph_executor_proxy_password_secret_name` (root module: `executor_sourcegraph_executor_proxy_password_secret_name`) reads the executor proxy password from a Google Secret Manager secret at VM boot instead of templating it into the instance's startup script, so it stays out of Terraform state and instance metadata. `sourcegraph_executor_proxy_password` is now optional; set exactly one of the two. Requires Terraform >= 1.2.0.

### Fixed

- The executor startup script no longer traces `sourcegraph_executor_proxy_password` and `docker_auth_config` to the serial console, and writes `/etc/systemd/system/executor.env` with mode `0600`.

- **BREAKING**: We refactored the terraform module to follow [best practices](https://cloud.google.com/docs/terraform/best-practices-for-terraform). It is recommended to re-create all resources.
