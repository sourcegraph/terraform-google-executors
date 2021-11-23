# Terraform module for Sourcegraph executors (GCP)

This repository provides a [Terraform module](https://learn.hashicorp.com/tutorials/terraform/module-use?in=terraform/modules) to provision [Sourcegraph executor](https://docs.sourcegraph.com/admin/executors) compute resources on Google Cloud. If you are installing executors for the first time, [follow our complete setup guide](https://docs.sourcegraph.com/admin/deploy_executors).

![Infrastructure overview](https://raw.githubusercontent.com/sourcegraph/terraform-google-executors/master/images/infrastructure.png)

## Usage examples

There are several examples in the [`examples`](https://github.com/sourcegraph/terraform-google-executors/blob/master/examples) directory.

### [`examples/single-executor`](https://github.com/sourcegraph/terraform-google-executors/blob/master/examples/single-executor)

This example uses the [root module](https://registry.terraform.io/modules/sourcegraph/executors/google/latest) that provisions a network, a Docker registry mirror, and a set of resources to run _one_ type of executor. To provision more than one type of executor (multiple queues or multiple environments), see the following `multiple-executors` example.

The following variables must be supplied:

**Note**: these variables must be set in tandem with changes to the target [Sourcegraph deployment](https://docs.sourcegraph.com/admin/deploy_executors).

- `executor_sourcegraph_external_url`: The URL from which the target Sourcegraph instance is accessible from the executor instances.
- `executor_sourcegraph_executor_proxy_password`: The shared executor password defined in Sourcegraph. The value must be the same as the `executors.accessToken` site setting described in [Configuring executors and instance communication](https://docs.sourcegraph.com/admin/deploy_executors#configuring-executors-and-instance-communication).
- `executor_queue_name`: The name of the target queue to process (e.g., `codeintel`, `batches`).
- `executor_metrics_environment_label`: The name of the target environment (e.g., `staging`, `prod`). This value must be the same as the `EXECUTOR_METRIC_ENVIRONMENT_LABEL` environment variable as described in [Configuring auto scaling](https://docs.sourcegraph.com/admin/deploy_executors#google).
- `executor_instance_tag`: Compute instances are tagged by this value by the key `executor_tag`. We recommend this value take the form `{executor_queue_name}-{executor_metrics_environment_label}`. This value must be the same as `INSTANCE_TAG` as described in [Configuring observability](https://docs.sourcegraph.com/admin/deploy_executors#google-1).

All of this module's variables are defined in [variables.tf](https://github.com/sourcegraph/terraform-google-executors/blob/master/variables.tf).

### [`examples/multiple-executors`](https://github.com/sourcegraph/terraform-google-executors/blob/master/examples/multiple-executors)

This example uses [networking](https://registry.terraform.io/modules/sourcegraph/executors/google/latest/submodules/networking), [docker-mirror](https://registry.terraform.io/modules/sourcegraph/executors/google/latest/submodules/docker-mirror), and [executors](https://registry.terraform.io/modules/sourcegraph/executors/google/latest/submodules/executors) submodules that provision a network, a Docker registry mirror, and sets of resources running one or more types of executors.

The following variables must be supplied:

- `sourcegraph_external_url`, `sourcegraph_executor_proxy_password`, `queue_name`, `metrics_environment_label`, and `instance_tag`: Analogous to the `executor_*` variables in the `single-executor` example.
- `resource_prefix`: A prefix unique to each set of compute resources. This prevents collisions between two uses of the `executors` module. We recommend this value be constructed the same way `instance_tag` is constructed.
- `docker_registry_mirror`: This variable is given the value `"http://${module.docker-mirror.ip_address}:5000"`, which converts the raw external IP address to an address resolvable by the executor instances.

If your deployment environment already has a Docker registry that can be used, only the `executor` submodule must be used (and references to the `networking` and `docker-mirror` modules can be dropped). The Docker registry mirror address can be supplied along with its containing network and subnetwork as pre-existing identifier literals.

All of these module's variables are defined in [modules/networking/variables.tf](https://github.com/sourcegraph/terraform-google-executors/blob/master/modules/networking/variables.tf), [modules/docker-mirror/variables.tf](https://github.com/sourcegraph/terraform-google-executors/blob/master/modules/docker-mirror/variables.tf), and [modules/executors/variables.tf](https://github.com/sourcegraph/terraform-google-executors/blob/master/modules/executors/variables.tf).

## Requirements

- [Terraform](https://www.terraform.io/) 0.13.7
- [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google/3.26.0) 3.26
