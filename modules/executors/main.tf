locals {
  prefix = var.resource_prefix != "" ? "${var.resource_prefix}-sourcegraph-" : "sourcegraph-"
}

resource "google_service_account" "sa" {
  # ID can be no longer than 28 characters.
  account_id   = "${substr(local.prefix, 0, 19)}executors"
  display_name = "${var.resource_prefix}${var.resource_prefix != "" ? " " : ""}sourcegraph executors"
}

resource "google_project_iam_member" "service_account_iam_log_writer" {
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "service_account_iam_metric_writer" {
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_compute_instance_template" "executor-instance-template" {
  name_prefix  = "${substr(local.prefix, 0, 28)}executor-"
  machine_type = var.machine_type

  # This is used for networking.
  tags = ["${local.prefix}executor"]

  labels = {
    "executor_tag" = var.instance_tag
  }

  scheduling {
    automatic_restart = false
    preemptible       = var.preemptible_machines
  }

  # Grant access to logging and monitoring APIs.
  service_account {
    email = google_service_account.sa.email
    scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  disk {
    source_image = var.machine_image
    disk_size_gb = var.boot_disk_size
    boot         = true
    disk_type    = "pd-ssd"
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id
    access_config {
      # I believe this is the default.
      network_tier = "PREMIUM"
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh.tpl", {
    environment_variables = {
      "EXECUTOR_DOCKER_REGISTRY_MIRROR"     = var.docker_registry_mirror
      "SOURCEGRAPH_EXTERNAL_URL"            = var.sourcegraph_external_url
      "SOURCEGRAPH_EXECUTOR_PROXY_PASSWORD" = var.sourcegraph_executor_proxy_password
      "EXECUTOR_MAXIMUM_NUM_JOBS"           = var.maximum_num_jobs
      "EXECUTOR_FIRECRACKER_NUM_CPUS"       = var.firecracker_num_cpus
      "EXECUTOR_FIRECRACKER_MEMORY"         = var.firecracker_memory
      "EXECUTOR_FIRECRACKER_DISK_SPACE"     = var.firecracker_disk_space
      "EXECUTOR_QUEUE_NAME"                 = var.queue_name
      "EXECUTOR_MAXIMUM_RUNTIME_PER_JOB"    = var.maximum_runtime_per_job
      "EXECUTOR_NUM_TOTAL_JOBS"             = var.num_total_jobs
      "EXECUTOR_MAX_ACTIVE_TIME"            = var.max_active_time
    }
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "executor" {
  name = "${local.prefix}executor"
  zone = var.zone

  version {
    instance_template = google_compute_instance_template.executor-instance-template.id
    name              = "primary"
  }

  base_instance_name = "${local.prefix}executor"

  update_policy {
    max_surge_percent = 100
    minimal_action    = "REPLACE"
    type              = "PROACTIVE"
  }
}

resource "google_compute_autoscaler" "executor-autoscaler" {
  # Need to use the beta provider here, some fields are otherwise not supported.
  provider = google-beta
  name     = "${local.prefix}executor-autoscaler"
  zone     = var.zone
  target   = google_compute_instance_group_manager.executor.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 300

    metric {
      name = "custom.googleapis.com/executors/queue/size"
      # TODO: Isn't there an AND missing here?
      filter = "resource.type = \"global\" metric.labels.queueName = \"${var.queue_name}\" AND metric.labels.environment = \"${var.metrics_environment_label}\""

      # 1 instance per N queued jobs.
      single_instance_assignment = var.jobs_per_instance_scaling
    }
  }
}

resource "google_compute_firewall" "executor-http-access" {
  name          = "${local.prefix}executor-http-firewall"
  network       = var.network_id
  target_tags   = ["${local.prefix}executor"]
  source_ranges = [var.http_access_cidr_range]

  # Expose the debug server port for metrics scraping.
  allow {
    protocol = "tcp"
    ports = [
      "9999" # exporter_exporter
    ]
  }
}

resource "google_compute_firewall" "executor-ssh-access" {
  name          = "${local.prefix}executor-ssh-firewall"
  network       = var.network_id
  target_tags   = ["${local.prefix}executor"]
  source_ranges = [var.ssh_access_cidr_range]

  # Expose the debug server port for metrics scraping.
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
