variable "region" {
  type        = string
  description = "The GCP region to create the network in."
}

variable "nat" {
  type        = bool
  default     = false
  description = "When true, the network will contain a NAT router. Use when executors should not get public IPs."
}

variable "nat_min_ports_per_vm" {
  type        = number
  default     = 1024
  description = "The minimum number of ports per VM to use when NAT mode is enabled. Consider increasing this when you see egress packets being dropped."
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "An optional prefix to add to all resources created."
  validation {
    condition     = var.resource_prefix == "" || can(regex("^[a-z].*", var.resource_prefix))
    error_message = "The variable executor_resource_prefix must start with a lowercase letter."
  }
}

variable "randomize_resource_names" {
  default     = false
  type        = bool
  description = "Use randomized names for resources. Disable if you are upgrading existing executors that were deployed using the legacy naming conventions, unless you want to recreate executor resources on GCP."
}
