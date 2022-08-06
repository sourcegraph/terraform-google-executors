variable "region" {
  type        = string
  description = "The GCP region to create the network in."
}

variable "nat" {
  type        = bool
  default     = false
  description = "When true, the network will contain a NAT router. Use when executors should not get public IPs."
}
