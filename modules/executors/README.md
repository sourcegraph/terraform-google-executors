# Executors module

This module provides the resources to provision [Sourcegraph executor](https://docs.sourcegraph.com/admin/executors) compute resources on Google Cloud. For a high-level overview of the resources deployed by this module, see the [root module](https://registry.terraform.io/modules/sourcegraph/executors/google/latest). This module includes the following resources:

- Google compute instance template
- Google compute group manager, and auto-scaler
- Google compute firewall
- Google service account membership to enable log and metric writes

This module does **not** automatically create networking or Docker mirror resources. The `network_id`, `subnet_id`, and `docker_registry_mirror` variables must be supplied explicitly with resources that have been previously created.

This module is often used with the sibling modules that create [networking](../../modules/networking/README.md) and [Docker mirror](../../modules/docker-mirror/README.md) resources which can be shared by multiple instances of the executor module (listening to different queues or being deployed in a different environment).
