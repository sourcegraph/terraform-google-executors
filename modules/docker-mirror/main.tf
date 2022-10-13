locals {
  network_tags = [
    substr("${random_id.compute_instance_network_tag.hex}-docker-mirror", 0, 64),
    "docker-mirror"
  ]
}

# Fetch the google project set in the currently used provider.
data "google_project" "project" {}

resource "random_id" "compute_disk_registry_data" {
  prefix      = var.resource_prefix
  byte_length = 6
}
resource "google_compute_disk" "registry-data" {
  name   = "${random_id.compute_disk_registry_data.hex}-docker-mirror"
  type   = "pd-ssd"
  zone   = var.zone
  size   = var.disk_size
  labels = var.labels
}

data "google_compute_image" "mirror_image" {
  count   = var.machine_image != "" ? 0 : 1
  project = "sourcegraph-ci"
  family  = "sourcegraph-executors-docker-mirror-4-0"
}

resource "random_id" "compute_instance_default" {
  prefix      = var.resource_prefix
  byte_length = 6
}
resource "google_compute_instance" "default" {
  name         = "${random_id.compute_instance_default.hex}-docker-mirror"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = local.network_tags

  labels = merge(
    {
      "executor_tag" = "${var.instance_tag_prefix}-docker-mirror"
    },
    var.labels,
  )

  service_account {
    email = google_service_account.sa.email
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  boot_disk {
    initialize_params {
      image = var.machine_image != "" ? var.machine_image : data.google_compute_image.mirror_image.0.self_link
      size  = var.boot_disk_size
      type  = "pd-ssd"
    }
  }

  attached_disk {
    source      = google_compute_disk.registry-data.self_link
    device_name = "registry-data"
    mode        = "READ_WRITE"
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")

  network_interface {
    network    = var.network_id
    network_ip = google_compute_address.static.address
    subnetwork = var.subnet_id
    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {
        # I believe this is the default.
        network_tier = "PREMIUM"
      }
    }
  }
}

resource "random_id" "compute_instance_network_tag" {
  prefix      = var.resource_prefix
  byte_length = 4
}
resource "random_id" "firewall_rule_prefix" {
  prefix      = var.resource_prefix
  byte_length = 4
}

resource "google_compute_firewall" "http" {
  name        = "${random_id.firewall_rule_prefix.hex}-docker-mirror-http"
  network     = var.network_id
  target_tags = local.network_tags

  source_ranges = var.http_access_cidr_ranges

  # Generally allow ICMP for pings etc.
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [
      "5000", # registry
      "9999"  # exporter_exporter
    ]
  }
}

resource "google_compute_firewall" "ssh" {
  name        = "${random_id.firewall_rule_prefix.hex}-docker-mirror-ssh"
  network     = var.network_id
  target_tags = local.network_tags

  # Google IAP source range.
  source_ranges = ["35.235.240.0/20"]

  # Expose port 22 for access to SSH.
  allow {
    protocol = "tcp"
    ports = [
      "22"
    ]
  }
}

resource "random_id" "compute_address_static" {
  prefix      = var.resource_prefix
  byte_length = 6
}

resource "google_compute_address" "static" {
  address_type = "INTERNAL"
  subnetwork   = var.subnet_id
  name         = random_id.compute_address_static.hex
}

resource "random_id" "service_account" {
  prefix      = var.resource_prefix
  byte_length = 4
}
resource "google_service_account" "sa" {
  account_id   = substr("${random_id.service_account.hex}-docker-mirror", 0, 30)
  display_name = "Docker registry mirror for Sourcegraph executors"
}

resource "google_project_iam_member" "service_account_iam_log_writer" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.sa.email}"
  project = data.google_project.project.id
}

resource "google_project_iam_member" "service_account_iam_metric_writer" {
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.sa.email}"
  project = data.google_project.project.id
}
