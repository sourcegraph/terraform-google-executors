# Terraform module for Sourcegraph executors (GCP)

This repository provides a [Terraform module](https://learn.hashicorp.com/tutorials/terraform/module-use?in=terraform/modules) to provision [Sourcegraph executor](https://sourcegraph.com/docs/admin/executors) compute resources on Google Cloud. If you are installing executors for the first time, [follow our complete setup guide](https://sourcegraph.com/docs/admin/executors/deploy_executors).

![Infrastructure overview](https://raw.githubusercontent.com/sourcegraph/terraform-google-executors/master/images/infrastructure.png)

This repository provides four submodules:

1. The [executors module](https://registry.terraform.io/modules/sourcegraph/executors/google/7.6.0/submodules/executors) provisions compute resources for executors.
2. The [docker-mirror module](https://registry.terraform.io/modules/sourcegraph/executors/google/7.6.0/submodules/docker-mirror) provisions a Docker registry pull-through cache.
3. The [networking module](https://registry.terraform.io/modules/sourcegraph/executors/google/7.6.0/submodules/networking) provisions a network to be shared by the executor and Docker registry resources.
4. The [credentials module](https://registry.terraform.io/modules/sourcegraph/executors/google/7.6.0/submodules/credentials) provisions credentials required by the Sourcegraph instance to enable observability and auto-scaling of executors.

The [multiple-executors example](https://github.com/sourcegraph/terraform-google-executors/blob/v7.6.0/examples/multiple-executors) uses the submodule directly to provision multiple executor resource groups performing different types of work. Follow this example if you are:
1. Provisioning executors for use with multiple features (e.g., both [auto-indexing](https://sourcegraph.com/docs/code_intelligence/explanations/auto_indexing) and [server-side batch changes](https://sourcegraph.com/docs/batch_changes/explanations/server_side)), or
2. Provisioning resources for multiple Sourcegraph instances (e.g., test, prod)

This repository also provides a [root module](https://registry.terraform.io/modules/sourcegraph/executors/google/7.6.0) combining the executors, network, and docker-mirror resources into an easier to use package.

The [single-executor example](https://github.com/sourcegraph/terraform-google-executors/blob/v7.6.0/examples/single-executor) uses the root module to provision a single executor type. Follow this example if you are deploying to a single Sourcegraph instance and using a single executors-backed feature.

## Requirements

- [Terraform](https://www.terraform.io/) 
  - 4.1.x and below: `~> 1.1.x`
  - 4.2.x and above: `>= 1.1.0, < 2.0.0`
- [hashicorp/google](https://registry.terraform.io/providers/hashicorp/google) 
  - `>= 5.0, < 8.0`

## Setup

Please follow our [setup guide](https://sourcegraph.com/docs/admin/executors/deploy_executors_terraform) on how to deploy
executors using Terraform.

## Sizing executor instances

The root module uses `executor_machine_type` to select the GCE machine type and defaults to `c2-standard-8` (8 vCPUs and 32 GB of memory). `c2-standard-8` is not required: you can use any machine type that meets the isolation requirements below. Choose its size based on per-job resources, concurrency, and measured workload, as described in Sourcegraph's [executor capacity guidance](https://sourcegraph.com/docs/self-hosted/executors/resource-sizing).

When using Firecracker, executors require an amd64 machine with KVM available at `/dev/kvm`. On Google Cloud, use a machine type that supports [nested virtualization](https://cloud.google.com/compute/docs/instances/nested-virtualization/overview). As of August 2026, Google Cloud does not support nested virtualization on E2, memory-optimized, AMD- or Arm-powered, or H4D VMs. Check that the selected machine type is supported in the executor's zone.

The default Sourcegraph executor image enables nested virtualization through Google Cloud's `enable-vmx` image license. If you set `executor_machine_image`, ensure the custom image includes the same [nested virtualization license](https://cloud.google.com/compute/docs/instances/nested-virtualization/enabling) and exposes `/dev/kvm`; selecting a compatible machine type alone does not enable it. If `executor_use_firecracker` is `false`, KVM is not required.

As a starting estimate, calculate instance capacity from the maximum concurrent jobs and per-job limits:

- vCPUs: `executor_maximum_num_jobs * executor_job_num_cpus`
- memory: `executor_maximum_num_jobs * executor_job_memory`
- Firecracker job disk: `executor_maximum_num_jobs * executor_firecracker_disk_space`

The defaults allow up to 2 concurrent jobs with limits of 4 vCPUs, 12 GB of memory, and 20 GB of Firecracker disk per job. This gives starting estimates of 8 vCPUs, 24 GB of memory, and 40 GB of job disk, plus capacity for the operating system, executor, and container runtime. These limits are not resource reservations, so tune them and any overcommit based on observed workloads. `executor_job_num_cpus` must be 1 or an even number when Firecracker is enabled, and `executor_firecracker_disk_space` must be a valid data size. The root module's `executor_boot_disk_size` defaults to 100 GB.

If you use the `executors` submodule directly, use the corresponding unprefixed variables: `machine_type`, `machine_image`, `maximum_num_jobs`, `job_num_cpus`, `job_memory`, `firecracker_disk_space`, `use_firecracker`, and `boot_disk_size`.

## Compatibility with Sourcegraph

The **major** and **minor** versions both need to match the Sourcegraph version the executors are talking to. Patch version **don't** need to match and it's generally advised to use the latest available.
For example:

| **Sourcegraph version** | **Terraform module version** |
|-------------------------|------------------------------|
| 3.37.0                  | 3.37.\*                      |
| 3.37.3                  | 3.37.\*                      |
| 3.38.0                  | 3.38.\*                      |
