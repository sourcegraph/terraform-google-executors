locals {
  prefix = var.resource_prefix != "" ? "${var.resource_prefix}-sg-" : "sg-"
}

# Fetch the google project set in the currently used provider.
data "google_project" "project" {}

resource "google_service_account" "metric_writer" {
  account_id   = "${substr(local.prefix, 0, 14)}-metric-writer"
  display_name = "Sourcegraph executors metric writer"
}

resource "google_project_iam_custom_role" "metric_writer" {
  role_id     = "${substr(var.resource_prefix, 0, 16)}MetricWriter"
  title       = "Sourcegraph executors metric writer"
  description = "Used to ingest a scaling metric for executors autoscaling"
  permissions = ["monitoring.timeSeries.create"]
}

resource "google_project_iam_member" "metric_writer" {
  role    = google_project_iam_custom_role.metric_writer.id
  member  = "serviceAccount:${google_service_account.metric_writer.email}"
  project = data.google_project.project.id
}

resource "google_service_account_key" "metric_writer" {
  service_account_id = google_service_account.metric_writer.name
}
