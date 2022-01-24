terraform {
  required_version = ">= 0.13.7, < 0.15.0"
  required_providers {
    google = "~> 3.26"
    google-beta = "~> 3.26"
  }
}

provider "google-beta" {
  region  = var.region
  zone    = var.zone
}