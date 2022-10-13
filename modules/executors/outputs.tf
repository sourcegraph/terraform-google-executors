output "service_account_email" {
  value       = google_service_account.sa.email
  description = "The service account email for the executor service account."
}

output "instance_group" {
  value       = google_compute_instance_group_manager.executor
  description = "The executor instance group."
}

output "instance_group_self_link" {
  value       = google_compute_instance_group_manager.executor.self_link
  description = "The self link of the executor instance group."
}
