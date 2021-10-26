variable "zone" {
  type        = string
  description = "The Google zone to create the docker mirror resources in."
}

variable "network_id" {
  type        = string
  description = "The network to run the VM in."
}

variable "subnet_id" {
  type        = string
  description = "The subnet to run the VM in."
}

variable "machine_image" {
  type        = string
  default     = "projects/sourcegraph-ci/global/images/executor-docker-mirror-98fcbdf9b8-113810"
  description = "Docker registry mirror node machine disk image to use for creating the boot volume."
}

variable "machine_type" {
  type        = string
  default     = "n1-standard-2" // 2 vCPU, 7.5GB
  description = "Docker registry mirror node machine type."
}

variable "boot_disk_size" {
  type        = number
  default     = 64 // 64GB
  description = "Docker registry mirror node disk size in GB."
}

variable "ssh_access_cidr_range" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR range from where SSH access to the Docker registry is acceptable."
}

variable "http_access_cidr_range" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR range from where HTTP access to the Docker registry is acceptable."
}

variable "http_metrics_access_cidr_range" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR range from where HTTP access to scrape metrics from the Docker registry is acceptable."
}

variable "instance_tag" {
  type        = string
  description = "A label tag to add to all the machines; can be used for filtering out the right instances in stackdriver monitoring and in Prometheus instance discovery."
}
