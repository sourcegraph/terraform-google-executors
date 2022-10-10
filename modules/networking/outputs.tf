output "network_id" {
  value       = google_compute_network.default.id
  description = "The network to run the VM in."
}

output "subnet_id" {
  value       = google_compute_subnetwork.default.id
  description = "The subnet to run the VM in."
}

output "ip_cidr" {
  value       = local.ip_cidr
  description = "The internal address that is owned by the subnetwork."
}

output "nat_ip" {
  value       = var.nat == true ? [google_compute_address.nat.0.address] : []
  description = "The list of NAT router address when executors should not get public IPs."
}
