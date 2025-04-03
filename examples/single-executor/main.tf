module "executors" {
  source  = "sourcegraph/executors/google"
  version = "6.2.0" # LATEST

  region                                       = local.region
  zone                                         = local.zone
  executor_instance_tag                        = "codeintel-prod"
  executor_sourcegraph_external_url            = "https://sourcegraph.acme.com"
  executor_sourcegraph_executor_proxy_password = "hunter2"
  executor_queue_name                          = "codeintel"
  executor_metrics_environment_label           = "prod"
  executor_use_firecracker                     = true
}
