variable "region" {
  type        = string
  description = "region"
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "An optional prefix to add to all resources created."
}

variable "project" {
  type        = string
  default     = ""
  description = "The GCP project ID."
}
