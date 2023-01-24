output "ip_address" {
  value       = google_compute_address.static.address
  description = "The static IP address in the provided subnets CIDR range."
}
