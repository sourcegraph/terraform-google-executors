output "metric_writer_credentials_file" {
  value = google_service_account_key.metric_writer.private_key
}

output "instance_scraper_credentials_file" {
  value = google_service_account_key.instance_scraper.private_key
}
