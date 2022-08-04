locals {
  ip_cidr = "10.0.1.0/24"
}

resource "google_compute_network" "default" {
  name                    = "sourcegraph-executors"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "default" {
  name = "sourcegraph-executors-subnet"

  network       = google_compute_network.default.id
  ip_cidr_range = local.ip_cidr
  region        = var.region
}
