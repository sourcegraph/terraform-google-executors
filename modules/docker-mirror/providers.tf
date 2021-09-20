terraform {
  required_version = "0.13.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.26"
    }
  }
}
