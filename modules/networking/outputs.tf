output "network_id" {
  value = google_compute_network.default.id
}

output "subnet_id" {
  value = google_compute_subnetwork.default.id
}

output "ip_cidr" {
  value = local.ip_cidr
}

output "nat_ip" {
  value = var.nat == true ? [google_compute_address.nat.0.address] : []
}
