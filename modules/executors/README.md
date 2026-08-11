# Executors module

This module provides the resources to provision [Sourcegraph executor](https://docs.sourcegraph.com/admin/executors) compute resources on Google Cloud. For a high-level overview of the resources deployed by this module, see the [root module](https://registry.terraform.io/modules/sourcegraph/executors/google/7.6.0). This module includes the following resources:

- Google compute instance template
- Google compute group manager, and auto-scaler
- Google compute firewall
- Google service account membership to enable log and metric writes

This module does **not** automatically create networking or Docker mirror resources. The `network_id`, `subnet_id`, and `docker_registry_mirror` variables must be supplied explicitly with resources that have been previously created.

This module is often used with the sibling modules that create [networking](https://registry.terraform.io/modules/sourcegraph/executors/google/7.6.0/submodules/networking) and [Docker mirror](https://registry.terraform.io/modules/sourcegraph/executors/google/7.6.0/submodules/docker-mirror) resources which can be shared by multiple instances of the executor module (listening to different queues or being deployed in a different environment).

## Sizing executor instances

The `machine_type` variable selects the GCE machine type and defaults to `c2-standard-8` (8 vCPUs and 32 GB of memory). `c2-standard-8` is not required: you can use any machine type that meets the isolation requirements below. Choose its size based on per-job resources, concurrency, and measured workload, as described in Sourcegraph's [executor capacity guidance](https://sourcegraph.com/docs/self-hosted/executors/resource-sizing).

When using Firecracker, executors require an amd64 machine with KVM available at `/dev/kvm`. On Google Cloud, use a machine type that supports [nested virtualization](https://cloud.google.com/compute/docs/instances/nested-virtualization/overview). As of August 2026, Google Cloud does not support nested virtualization on E2, memory-optimized, AMD- or Arm-powered, or H4D VMs. Check that the selected machine type is supported in the executor's zone.

The default Sourcegraph executor image enables nested virtualization through Google Cloud's `enable-vmx` image license. If you set `machine_image`, ensure the custom image includes the same [nested virtualization license](https://cloud.google.com/compute/docs/instances/nested-virtualization/enabling) and exposes `/dev/kvm`; selecting a compatible machine type alone does not enable it. If `use_firecracker` is `false`, KVM is not required.

As a starting estimate, calculate instance capacity from the maximum concurrent jobs and per-job limits:

- vCPUs: `maximum_num_jobs * job_num_cpus`
- memory: `maximum_num_jobs * job_memory`
- Firecracker job disk: `maximum_num_jobs * firecracker_disk_space`

The defaults allow up to 2 concurrent jobs with limits of 4 vCPUs, 12 GB of memory, and 20 GB of Firecracker disk per job. This gives starting estimates of 8 vCPUs, 24 GB of memory, and 40 GB of job disk, plus capacity for the operating system, executor, and container runtime. These limits are not resource reservations, so tune them and any overcommit based on observed workloads. `job_num_cpus` must be 1 or an even number when Firecracker is enabled, and `firecracker_disk_space` must be a valid data size. `boot_disk_size` defaults to 100 GB.
