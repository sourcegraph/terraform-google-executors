terraform {
  required_version = "0.13.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.26"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.26"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
