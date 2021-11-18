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

module "executors" {
  source  = "sourcegraph/executors/google"
  version = "0.0.16"

  region                                       = local.region
  zone                                         = local.zone
  executor_instance_tag                        = "codeintel-prod"
  executor_sourcegraph_external_url            = "https://sourcegraph.acme.com"
  executor_sourcegraph_executor_proxy_password = "hunter2"
  executor_queue_name                          = "codeintel"
  executor_metrics_environment_label           = "prod"
}
