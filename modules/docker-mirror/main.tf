locals {
  resource_prefix = (var.resource_prefix == "" || substr(var.resource_prefix, -1, -2) == "-") ? var.resource_prefix : "${var.resource_prefix}-"

  network_tags = var.randomize_resource_names ? [
    substr("${local.resource_prefix}docker-mirror-${random_id.compute_instance_network_tag[0].hex}", 0, 64),
    "docker-mirror"
  ] : []

  resource_values = {
    compute_disk = {
      name   = var.randomize_resource_names ? "${local.resource_prefix}docker-mirror-${random_id.compute_disk_registry_data[0].hex}" : "docker-registry-data"
      labels = var.randomize_resource_names ? merge({ executor_tag = "${var.instance_tag_prefix}-docker-mirror" }, var.labels) : { executor_tag = "${var.instance_tag_prefix}-docker-mirror" }
    }
    compute_instance = {
      name   = var.randomize_resource_names ? "${local.resource_prefix}docker-mirror-${random_id.compute_instance_default[0].hex}" : "sourcegraph-executors-docker-registry-mirror"
      tags   = var.randomize_resource_names ? local.network_tags : ["docker-registry-mirror"]
      labels = var.randomize_resource_names ? merge({ executor_tag = "${var.instance_tag_prefix}-docker-mirror" }, var.labels) : { executor_tag = "${var.instance_tag_prefix}-docker-mirror" }
    }
    compute_firewall = {
      name_prefix = var.randomize_resource_names ? "${local.resource_prefix}docker-mirror-${random_id.firewall_rule_prefix[0].hex}-" : "sourcegraph-executor-docker-mirror-"
      target_tags = var.randomize_resource_names ? local.network_tags : ["docker-registry-mirror"]
    }
    compute_address = {
      name = var.randomize_resource_names ? "${local.resource_prefix}docker-registry-mirror-${random_id.compute_address_static[0].hex}" : "sg-executor-docker-registry-mirror"
    }
    service_account = {
      account_id = var.randomize_resource_names ? substr("${local.resource_prefix}docker-mirror-${random_id.service_account[0].hex}", 0, 30) : "sg-executor-docker-registry"
    }
  }
}

# Fetch the google project set in the currently used provider.
data "google_project" "project" {}

resource "random_id" "compute_disk_registry_data" {
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 6
}
resource "google_compute_disk" "registry-data" {
  count  = var.use_local_ssd ? 0 : 1
  name   = local.resource_values.compute_disk.name
  type   = "pd-ssd"
  zone   = var.zone
  size   = var.disk_size
  labels = local.resource_values.compute_disk.labels
}

data "google_compute_image" "mirror_image" {
  count   = var.machine_image != "" ? 0 : 1
  project = "sourcegraph-ci"
  family  = "sourcegraph-executors-docker-mirror-6-3"
}

resource "random_id" "compute_instance_default" {
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 6
}
resource "google_compute_instance" "default" {
  name         = local.resource_values.compute_instance.name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = local.resource_values.compute_instance.tags

  allow_stopping_for_update = true

  labels = local.resource_values.compute_instance.labels

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

  dynamic "scratch_disk" {
    for_each = var.use_local_ssd ? [1] : []
    content {
      interface = "NVME"
    }
  }

  dynamic "attached_disk" {
    for_each = var.use_local_ssd ? [] : [1]
    content {
      source      = google_compute_disk.registry-data[0].self_link
      device_name = "registry-data"
      mode        = "READ_WRITE"
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh.tpl", {
    environment_variables = {
      "USE_LOCAL_SSD" = var.use_local_ssd
    }
  })

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
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 4
}
resource "random_id" "firewall_rule_prefix" {
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 4
}

resource "google_compute_firewall" "http" {
  name        = "${local.resource_values.compute_firewall.name_prefix}http"
  network     = var.network_id
  target_tags = local.resource_values.compute_firewall.target_tags

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
  name        = "${local.resource_values.compute_firewall.name_prefix}ssh"
  network     = var.network_id
  target_tags = local.resource_values.compute_firewall.target_tags

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
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 6
}

resource "google_compute_address" "static" {
  address_type = "INTERNAL"
  subnetwork   = var.subnet_id
  name         = local.resource_values.compute_address.name
}

resource "random_id" "service_account" {
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 4
}
resource "google_service_account" "sa" {
  account_id   = local.resource_values.service_account.account_id
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
