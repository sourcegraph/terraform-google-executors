variable "zone" {
  type        = string
  description = "The Google zone to provision the Executor compute resources in."
}

variable "network_id" {
  type        = string
  description = "The network to run the VM in."
}

variable "subnet_id" {
  type        = string
  description = "The subnet to run the VM in."
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "An optional prefix to add to all resources created."
  validation {
    condition     = var.resource_prefix == "" || can(regex("^[a-z].*", var.resource_prefix))
    error_message = "The variable resource_prefix must start with a lowercase letter."
  }
}

variable "machine_image" {
  type        = string
  default     = ""
  description = "Executor node machine disk image to use for creating the boot volume. Leave empty to use latest compatible with the Sourcegraph version."
}

variable "machine_type" {
  type        = string
  default     = "c2-standard-8" // 8 vCPU, 32GB
  description = "Executor node machine type"
}

variable "boot_disk_size" {
  type        = number
  default     = 100 // 100GB
  description = "Executor node disk size in GB"
}

variable "preemptible_machines" {
  type        = bool
  default     = false
  description = "Whether to use preemptible machines instead of standard machines; usually way cheaper but might be terminated at any time"
}

variable "instance_tag" {
  type        = string
  description = "A label tag to add to all the executors; can be used for filtering out the right instances in stackdriver monitoring"
}

variable "http_access_cidr_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DEPRECATED. This is not used anymore."
}

variable "sourcegraph_external_url" {
  type        = string
  description = "The externally accessible URL of the target Sourcegraph instance"
}

variable "sourcegraph_executor_proxy_password" {
  type        = string
  description = "The shared password used to authenticate requests to the internal executor proxy"
  sensitive   = true
}

variable "queue_name" {
  type        = string
  default     = ""
  description = "The single queue from which the executor should dequeue jobs. Either this or `queue_names` is required"
}

variable "queue_names" {
  type        = list(string)
  default     = null
  description = "The multiple queues from which the executor should dequeue jobs. Either this or `queue_name` is required"
}

variable "maximum_runtime_per_job" {
  type        = string
  default     = "45m"
  description = "The maximum wall time that can be spent on a single job"
}

variable "maximum_num_jobs" {
  type        = number
  default     = 2
  description = "The number of jobs to run concurrently per executor instance"
}

variable "num_total_jobs" {
  type        = number
  default     = 200
  description = "The maximum number of jobs that will be dequeued by the worker"
}

variable "max_active_time" {
  type        = string
  default     = "12h"
  description = "The maximum time that can be spent by the worker dequeueing records to be handled"
}

variable "job_num_cpus" {
  type        = number
  default     = 4
  description = "The number of CPUs to allocate to each virtual machine or container"
}

variable "firecracker_num_cpus" {
  type        = number
  default     = 4
  description = "The number of CPUs to give to each firecracker VM"
}

variable "job_memory" {
  type        = string
  default     = "12GB"
  description = "The amount of memory to allocate to each virtual machine or container"
}

variable "firecracker_memory" {
  type        = string
  default     = "12GB"
  description = "The amount of memory to give to each firecracker VM"
}

variable "firecracker_disk_space" {
  type        = string
  default     = "20GB"
  description = "The amount of disk space to give to each firecracker VM"
}

variable "use_firecracker" {
  type        = bool
  default     = true
  description = "Whether to isolate commands in virtual machines"
}

variable "min_replicas" {
  type        = number
  default     = 1
  description = "The minimum number of executor instances to run in the autoscaling group"
}

variable "max_replicas" {
  type        = number
  default     = 1
  description = "The maximum number of executor instances to run in the autoscaling group"
}

variable "jobs_per_instance_scaling" {
  type        = number
  default     = 20
  description = "The amount of jobs a single instance should have in queue. Used for autoscaling."
}

variable "metrics_environment_label" {
  type        = string
  description = "The value for environment by which to filter the custom metrics"
}

variable "docker_registry_mirror" {
  type        = string
  default     = ""
  description = "A URL to a docker registry mirror to use (falling back to docker.io)"
}

variable "docker_registry_mirror_node_exporter_url" {
  type        = string
  default     = ""
  description = "A URL to a docker registry mirror node exporter to scrape (optional)"
}

variable "assign_public_ip" {
  type        = bool
  default     = true
  description = "If false, no public IP will be associated with the executors."
}

variable "docker_auth_config" {
  type        = string
  default     = ""
  description = "If provided, this docker auth config file will be used to authorize image pulls. See [Using private registries](https://docs.sourcegraph.com/admin/deploy_executors#using-private-registries) for how to configure."
  sensitive   = true
}

variable "labels" {
  type        = map(string)
  description = "A map of labels to add to compute instances"
  default     = {}
}

variable "randomize_resource_names" {
  default     = false
  type        = bool
  description = "Use randomized names for resources. Disable if you are upgrading existing executors that were deployed using the legacy naming conventions, unless you want to recreate executor resources on GCP."
}

variable "use_local_ssd" {
  type        = bool
  default     = false
  description = "Use a local SSD for the data dir of ignite."
}

variable "private_ca_cert_path" {
  type        = string
  default     = ""
  description = "Path to the private CA certificate file"
}
