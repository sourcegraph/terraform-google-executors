variable "gcp_project_id" {
  type        = string
  description = "Project ID on GCP where the resources should be created in."
}

variable "gcp_region" {
  type        = string
  default     = "us-central1"
  description = "region"
}

variable "gcp_zone" {
  type        = string
  default     = "us-central1-c"
  description = "zone"
}
