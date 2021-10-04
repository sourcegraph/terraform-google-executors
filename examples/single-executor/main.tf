module "executors" {
  source  = "sourcegraph/executors/google"
  version = "0.0.6"

  project_id                                   = local.project_id # REMOVE ME
  region                                       = local.region
  zone                                         = local.zone
  executor_instance_tag                        = "codeintel-prod"
  executor_sourcegraph_external_url            = "https://sourcegraph.acme.com"
  executor_sourcegraph_executor_proxy_username = "executor"
  executor_sourcegraph_executor_proxy_password = "hunter2"
  executor_queue_name                          = "codeintel"
  executor_metrics_environment_label           = "prod"
}
