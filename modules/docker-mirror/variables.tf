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
  default     = ""
  description = "Docker registry mirror node machine disk image to use for creating the boot volume. Leave empty to use latest compatible with the Sourcegraph version."
}

variable "machine_type" {
  type        = string
  default     = "n1-standard-2" // 2 vCPU, 7.5GB
  description = "Docker registry mirror node machine type."
}

variable "boot_disk_size" {
  type        = number
  default     = 32
  description = "Docker registry mirror node disk size in GB."
}

variable "disk_size" {
  type        = number
  default     = 64
  description = "Persistent Docker registry mirror disk size in GB."
}

variable "http_access_cidr_ranges" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "CIDR range from where HTTP access to the Docker registry is acceptable."
}

variable "http_metrics_access_cidr_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DEPRECATED. This is not used anymore."
}

variable "instance_tag_prefix" {
  type        = string
  description = "A label tag to add to all the machines; can be used for filtering out the right instances in stackdriver monitoring and in Prometheus instance discovery."
}

variable "assign_public_ip" {
  type        = bool
  default     = true
  description = "If false, no public IP will be associated with the executors."
}
