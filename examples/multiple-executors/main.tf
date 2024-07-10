module "networking" {
  source  = "sourcegraph/executors/google//modules/networking"
  version = "5.5.0" # LATEST

  region = local.region
}

module "docker-mirror" {
  source  = "sourcegraph/executors/google//modules/docker-mirror"
  version = "5.5.0" # LATEST

  zone                = local.zone
  network_id          = module.networking.network_id
  subnet_id           = module.networking.subnet_id
  instance_tag_prefix = "prod"
}

module "executors-codeintel" {
  source  = "sourcegraph/executors/google//modules/executors"
  version = "5.5.0" # LATEST

  zone                                = local.zone
  network_id                          = module.networking.network_id
  subnet_id                           = module.networking.subnet_id
  resource_prefix                     = "codeintel-prod"
  instance_tag                        = "codeintel-prod"
  sourcegraph_external_url            = "https://sourcegraph.acme.com"
  sourcegraph_executor_proxy_password = "hunter2"
  queue_name                          = "codeintel"
  metrics_environment_label           = "prod"
  docker_registry_mirror              = "http://${module.docker-mirror.ip_address}:5000"
  #   docker_registry_mirror_node_exporter_url = "http://${module.docker-mirror.ip_address}:9999"
  use_firecracker = true
}

module "executors-batches" {
  source  = "sourcegraph/executors/google//modules/executors"
  version = "5.5.0" # LATEST

  zone                                = local.zone
  network_id                          = module.networking.network_id
  subnet_id                           = module.networking.subnet_id
  resource_prefix                     = "batches-prod"
  instance_tag                        = "batches-prod"
  sourcegraph_external_url            = "https://sourcegraph.acme.com"
  sourcegraph_executor_proxy_password = "hunter2"
  queue_name                          = "batches"
  metrics_environment_label           = "prod"
  docker_registry_mirror              = "http://${module.docker-mirror.ip_address}:5000"
  #   docker_registry_mirror_node_exporter_url = "http://${module.docker-mirror.ip_address}:9999"
  use_firecracker = true
}
