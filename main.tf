module "gcp-networking" {
  source = "./modules/networking"

  region = var.gcp_region
}

module "gcp-docker-mirror" {
  source = "./modules/docker-mirror"

  network_id    = module.gcp-networking.network_id
  subnet_id     = module.gcp-networking.subnet_id
  zone          = var.gcp_zone
  machine_image = "ubuntu-os-cloud/ubuntu-1804-bionic-v20200701"
}

module "gcp-executors" {
  source = "./modules/executors"

  machine_image = "projects/sourcegraph-ci/global/images/executor-a7ce591963-1631546817"
}
