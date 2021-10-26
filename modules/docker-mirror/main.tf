resource "google_compute_instance" "default" {
  name         = "sourcegraph-executors-docker-registry-mirror"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["docker-registry-mirror"]

  labels = {
    "executor_tag" = "${var.instance_tag_prefix}-docker-mirror"
  }

  service_account {
    email = google_service_account.sa.email
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  boot_disk {
    initialize_params {
      image = var.machine_image
      size  = var.boot_disk_size
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = var.network_id
    network_ip = google_compute_address.static.address
    subnetwork = var.subnet_id
    access_config {
      network_tier = "PREMIUM"
    }
  }
}

resource "google_compute_firewall" "http" {
  name        = "sourcegraph-executor-docker-mirror-http"
  network     = var.network_id
  target_tags = ["docker-registry-mirror"]

  source_ranges = [var.http_access_cidr_range]

  # Generally allow ICMP for pings etc.
  allow {
    protocol = "icmp"
  }

  # Expose the registry server port.
  allow {
    protocol = "tcp"
    ports = [
      "5000"
    ]
  }
}

resource "google_compute_firewall" "http-metrics-access" {
  name        = "sourcegraph-executor-docker-mirror-http-metrics"
  network     = var.network_id
  target_tags = ["docker-registry-mirror"]

  source_ranges = [var.http_metrics_access_cidr_range]

  # Expose the debug server port for metrics scraping.
  allow {
    protocol = "tcp"
    ports = [
      "9999" # exporter_exporter
    ]
  }
}

resource "google_compute_firewall" "ssh" {
  name        = "sourcegraph-executor-docker-mirror-ssh"
  network     = var.network_id
  target_tags = ["docker-registry-mirror"]

  source_ranges = [var.ssh_access_cidr_range]

  # Generally allow ICMP for pings etc.
  allow {
    protocol = "icmp"
  }

  # Expose port 22 for access to SSH.
  allow {
    protocol = "tcp"
    ports = [
      "22"
    ]
  }
}

resource "google_compute_address" "static" {
  address_type = "INTERNAL"
  subnetwork   = var.subnet_id
  name         = "sg-executor-docker-registry-mirror"
}

resource "google_service_account" "sa" {
  account_id   = "sg-executor-docker-registry"
  display_name = "Docker registry mirror for Sourcegraph executors"
}

resource "google_project_iam_member" "service_account_iam_log_writer" {
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "service_account_iam_metric_writer" {
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.sa.email}"
}
