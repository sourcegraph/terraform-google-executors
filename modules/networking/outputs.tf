output "network_id" {
  value = google_compute_network.default.id
}

output "subnet_id" {
  value = google_compute_subnetwork.default.id
}
