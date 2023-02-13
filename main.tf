locals {
  // can't set a default value for resource_prefix as it potentially breaks legacy deployments that didn't set a prefix
  // some kind of prefix is required when randomizing to ensure naming constraints are met (start with a lowercase letter)
  resource_prefix = var.randomize_resource_names ? (var.executor_resource_prefix == "" ? "src-" : var.executor_resource_prefix) : var.executor_resource_prefix
}

module "gcp-networking" {
  source = "./modules/networking"

  randomize_resource_names = var.randomize_resource_names
  resource_prefix          = local.resource_prefix
  region                   = var.region
  nat                      = var.private_networking
}

module "gcp-docker-mirror" {
  source = "./modules/docker-mirror"

  randomize_resource_names = var.randomize_resource_names
  resource_prefix          = local.resource_prefix
  zone                     = var.zone
  network_id               = module.gcp-networking.network_id
  subnet_id                = module.gcp-networking.subnet_id
  http_access_cidr_ranges  = [module.gcp-networking.ip_cidr]
  machine_image            = var.docker_mirror_machine_image
  machine_type             = var.docker_mirror_machine_type
  boot_disk_size           = var.docker_mirror_boot_disk_size
  instance_tag_prefix      = var.executor_instance_tag
  assign_public_ip         = var.private_networking ? false : true
  use_local_ssd            = var.docker_mirror_use_local_ssd
}

module "gcp-executors" {
  source = "./modules/executors"

  randomize_resource_names                 = var.randomize_resource_names
  zone                                     = var.zone
  network_id                               = module.gcp-networking.network_id
  subnet_id                                = module.gcp-networking.subnet_id
  resource_prefix                          = local.resource_prefix
  machine_image                            = var.executor_machine_image
  machine_type                             = var.executor_machine_type
  boot_disk_size                           = var.executor_boot_disk_size
  preemptible_machines                     = var.executor_preemptible_machines
  instance_tag                             = var.executor_instance_tag
  sourcegraph_external_url                 = var.executor_sourcegraph_external_url
  sourcegraph_executor_proxy_password      = var.executor_sourcegraph_executor_proxy_password
  queue_name                               = var.executor_queue_name
  use_firecracker                          = var.executor_use_firecracker
  maximum_runtime_per_job                  = var.executor_maximum_runtime_per_job
  maximum_num_jobs                         = var.executor_maximum_num_jobs
  num_total_jobs                           = var.executor_num_total_jobs
  max_active_time                          = var.executor_max_active_time
  job_num_cpus                             = var.executor_job_num_cpus != "" ? var.executor_job_num_cpus : var.executor_firecracker_num_cpus
  job_memory                               = var.executor_job_memory != "" ? var.executor_job_memory : var.executor_firecracker_memory
  firecracker_disk_space                   = var.executor_firecracker_disk_space
  min_replicas                             = var.executor_min_replicas
  max_replicas                             = var.executor_max_replicas
  jobs_per_instance_scaling                = var.executor_jobs_per_instance_scaling
  metrics_environment_label                = var.executor_metrics_environment_label
  docker_registry_mirror                   = "http://${module.gcp-docker-mirror.ip_address}:5000"
  docker_registry_mirror_node_exporter_url = "http://${module.gcp-docker-mirror.ip_address}:9999"
  assign_public_ip                         = var.private_networking ? false : true
  docker_auth_config                       = var.executor_docker_auth_config
  use_local_ssd                            = var.executor_use_local_ssd
}
