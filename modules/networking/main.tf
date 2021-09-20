resource "google_compute_network" "default" {
  name                    = "sourcegraph-executors"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "default" {
  name = "sourcegraph-executors-subnet"

  network       = google_compute_network.default.id
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
}
