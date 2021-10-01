variable "zone" {
  type        = string
  description = "zone"
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "machine_image" {
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-1804-bionic-v20200701"
  description = "Docker registry mirror node machine disk image to use for creating the boot volume"
}

variable "machine_type" {
  type        = string
  default     = "n1-standard-2" // 2 vCPU, 7.5GB
  description = "Docker registry mirror node machine type"
}

variable "boot_disk_size" {
  type        = number
  default     = 64 // 64GB
  description = "Docker registry mirror node disk size in GB"
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
