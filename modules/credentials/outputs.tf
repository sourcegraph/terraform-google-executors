output "metric_writer_credentials_file" {
  value       = google_service_account_key.metric_writer.private_key
  description = "The credential file of the Metrics Writer Service Account."
}
