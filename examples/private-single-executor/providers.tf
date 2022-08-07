locals {
  project = "<your GCP project name here>"
  region  = "us-central1"
  zone    = "us-central1-c"
}

provider "google-beta" {
  project = local.project
  region  = local.region
  zone    = local.zone
}

provider "google" {
  project = local.project
  region  = local.region
  zone    = local.zone
}
