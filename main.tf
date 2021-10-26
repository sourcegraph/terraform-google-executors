module "gcp-networking" {
  source = "./modules/networking"

  region = var.region
}

module "gcp-docker-mirror" {
  source = "./modules/docker-mirror"

  zone                   = var.zone
  network_id             = module.gcp-networking.network_id
  subnet_id              = module.gcp-networking.subnet_id
  machine_image          = var.docker_mirror_machine_image
  machine_type           = var.docker_mirror_machine_type
  boot_disk_size         = var.docker_mirror_boot_disk_size
  ssh_access_cidr_range  = var.docker_mirror_ssh_access_cidr_range
  http_access_cidr_range = var.docker_mirror_http_access_cidr_range
  instance_tag_prefix    = var.executor_instance_tag
}

module "gcp-executors" {
  source = "./modules/executors"

  zone                                = var.zone
  network_id                          = module.gcp-networking.network_id
  subnet_id                           = module.gcp-networking.subnet_id
  resource_prefix                     = var.executor_resource_prefix
  machine_image                       = var.executor_machine_image
  machine_type                        = var.executor_machine_type
  boot_disk_size                      = var.executor_boot_disk_size
  preemptible_machines                = var.executor_preemptible_machines
  instance_tag                        = var.executor_instance_tag
  ssh_access_cidr_range               = var.executor_ssh_access_cidr_range
  http_access_cidr_range              = var.executor_http_access_cidr_range
  sourcegraph_external_url            = var.executor_sourcegraph_external_url
  sourcegraph_executor_proxy_password = var.executor_sourcegraph_executor_proxy_password
  queue_name                          = var.executor_queue_name
  maximum_runtime_per_job             = var.executor_maximum_runtime_per_job
  maximum_num_jobs                    = var.executor_maximum_num_jobs
  num_total_jobs                      = var.executor_num_total_jobs
  max_active_time                     = var.executor_max_active_time
  firecracker_num_cpus                = var.executor_firecracker_num_cpus
  firecracker_memory                  = var.executor_firecracker_memory
  firecracker_disk_space              = var.executor_firecracker_disk_space
  min_replicas                        = var.executor_min_replicas
  max_replicas                        = var.executor_max_replicas
  jobs_per_instance_scaling           = var.executor_jobs_per_instance_scaling
  metrics_environment_label           = var.executor_metrics_environment_label
  docker_registry_mirror              = module.gcp-docker-mirror.ip_address
}
