# Docker mirror module

This module provides a hosted Docker registry pull-through cache to be used by [Sourcegraph executor](https://docs.sourcegraph.com/admin/executors). It is strongly recommended to deploy a Docker mirror as a cache to reduce rate limiting by the public [Docker Hub registry](https://hub.docker.com/). We have also seen deploying a Docker mirror in the same physical zone as the executors significantly decreased latencies during image pulls.

When using the sibling [executors module](https://registry.terraform.io/modules/sourcegraph/executors/google/6.5.0/submodules/executors), the `network_id` and `subnet_id` values must match and the executor module `docker_registry_mirror` value should match `"http://${ip_address}:5000"` (where `ip_address` is this module's output).
