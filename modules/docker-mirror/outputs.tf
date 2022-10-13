output "ip_address" {
  value       = google_compute_address.static.address
  description = "The static IP address in the provided subnets CIDR range."
}

output "service_account_email" {
  value       = google_service_account.sa.email
  description = "The service account email for the docker mirror."
}

output "instance" {
  value       = google_compute_instance.default
  description = "The docker mirror instance."
}

output "instance_self_link" {
  value       = google_compute_instance.default.self_link
  description = "The self link of the docker mirror instance."
}
