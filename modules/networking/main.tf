locals {
  ip_cidr = "10.0.1.0/24"
}


resource "random_id" "network" {
  prefix      = var.resource_prefix
  byte_length = 6
}
resource "google_compute_network" "default" {
  name                    = "${random_id.network.hex}-executors"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "random_id" "subnetwork" {
  prefix      = var.resource_prefix
  byte_length = 6
}
resource "google_compute_subnetwork" "default" {
  name = "${random_id.network.hex}-executors"

  network       = google_compute_network.default.id
  ip_cidr_range = local.ip_cidr
  region        = var.region
}

# If NAT mode is enabled, we create a custom router for our network.
resource "random_id" "router" {
  prefix      = var.resource_prefix
  byte_length = 6
}
resource "google_compute_router" "default" {
  count = var.nat ? 1 : 0

  name    = "${random_id.router.hex}-executors"
  region  = var.region
  network = google_compute_network.default.id
}

resource "random_id" "compute_address_nat" {
  prefix      = var.resource_prefix
  byte_length = 6
}
# Then NAT mode is enabled, we want a static IP for it.
resource "google_compute_address" "nat" {
  count = var.nat ? 1 : 0

  name   = "${random_id.compute_address_nat.hex}-executors"
  region = var.region
}

resource "random_id" "router_nat" {
  prefix      = var.resource_prefix
  byte_length = 6
}
resource "google_compute_router_nat" "default" {
  count = var.nat ? 1 : 0

  name                               = "${random_id.router_nat.hex}-executors"
  region                             = var.region
  router                             = google_compute_router.default.0.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat.0.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  min_ports_per_vm = var.nat_min_ports_per_vm
}
