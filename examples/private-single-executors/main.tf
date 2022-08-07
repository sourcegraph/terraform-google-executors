module "executors" {
  source = "../../modules/executors"

  zone = local.zone

  network_id       = module.networking.network_id
  subnet_id        = module.networking.subnet_id
  assign_public_ip = false

  instance_tag                        = "codeintel-prod"
  sourcegraph_external_url            = "https://sourcegraph.acme.com"
  sourcegraph_executor_proxy_password = "hunter2"
  queue_name                          = "codeintel"
  metrics_environment_label           = "prod"
  use_firecracker                     = true
}

module "networking" {
  source = "../../modules/networking"

  region = local.region

  nat = true
}
