locals {
  resource_prefix = (var.resource_prefix == "" || substr(var.resource_prefix, -1, -2) == "-") ? var.resource_prefix : "${var.resource_prefix}-"
  legacy_prefix   = local.resource_prefix != "" ? "${var.resource_prefix}-sourcegraph-" : "sourcegraph-"

  network_tags = var.randomize_resource_names ? [
    substr("${local.resource_prefix}executors-${random_id.compute_instance_network_tag[0].hex}", 0, 64),
    var.instance_tag,
    "executors"
  ] : []

  resource_values = {
    service_account = {
      account_id   = var.randomize_resource_names ? substr("${local.resource_prefix}executors-${random_id.service_account[0].hex}", 0, 30) : "${substr(local.legacy_prefix, 0, 19)}executors"
      display_name = var.randomize_resource_names ? "Service account for Sourcegraph executors" : "${var.resource_prefix}${var.resource_prefix != "" ? " " : ""}sourcegraph executors"
    }
    compute_instance_template = {
      name_prefix = var.randomize_resource_names ? "${substr(local.resource_prefix, 0, 28)}executors-" : "${substr(local.legacy_prefix, 0, 28)}executor-"
      tags        = var.randomize_resource_names ? local.network_tags : ["${local.legacy_prefix}executor"]
      labels      = var.randomize_resource_names ? merge({ executor_tag = var.instance_tag }, var.labels) : { executor_tag = var.instance_tag }
    }
    compute_instance_group_manager = {
      name               = var.randomize_resource_names ? "${local.resource_prefix}executors-${random_id.compute_instance_group_executor[0].hex}" : "${local.legacy_prefix}executor"
      base_instance_name = var.randomize_resource_names ? "${local.resource_prefix}executors-${random_id.compute_instance_group_executor[0].hex}" : "${local.legacy_prefix}executor"
    }
    compute_autoscaler = {
      name = var.randomize_resource_names ? "${local.resource_prefix}executors-autoscaler-${random_id.compute_instance_group_executor[0].hex}" : "${local.legacy_prefix}executor-autoscaler"
    }
    compute_firewall = {
      name        = var.randomize_resource_names ? "${local.resource_prefix}executors-ssh-${random_id.firewall_rule_prefix[0].hex}" : "${local.legacy_prefix}executor-ssh-firewall"
      target_tags = var.randomize_resource_names ? local.network_tags : ["${local.legacy_prefix}executor"]
    }
  }

  # if using local SSDs and using the default value of 100, lower it to 10, otherwise use the configured value either way.
  boot_disk_size = var.use_local_ssd ? (var.boot_disk_size == 100 ? 10 : var.boot_disk_size) : var.boot_disk_size

  queue_names = var.queue_names != null ? join(",", sort(var.queue_names)) : ""
  // TODO: this is how the field is set in util.workerOptions when metrics are initialised.
  // Should be split into a queue/queues metric field
  metric_queue_val = var.queue_name != "" ? var.queue_name : replace(local.queue_names, ",", "_")
}

# Fetch the google project set in the currently used provider.
data "google_project" "project" {}

resource "random_id" "service_account" {
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 4
}
resource "google_service_account" "sa" {
  account_id   = local.resource_values.service_account.account_id
  display_name = local.resource_values.service_account.display_name
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

data "google_compute_image" "executor_image" {
  count   = var.machine_image != "" ? 0 : 1
  project = "sourcegraph-ci"
  family  = "sourcegraph-executors-5-2"
}

resource "random_id" "compute_instance_network_tag" {
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 4
}
resource "google_compute_instance_template" "executor-instance-template" {
  # Need to use the beta provider here, some fields are otherwise not supported.
  provider     = google-beta
  name_prefix  = local.resource_values.compute_instance_template.name_prefix
  machine_type = var.machine_type

  # This is used for networking.
  tags = local.resource_values.compute_instance_template.tags

  labels = local.resource_values.compute_instance_template.labels

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
    source_image = var.machine_image != "" ? var.machine_image : data.google_compute_image.executor_image.0.self_link
    disk_size_gb = local.boot_disk_size
    boot         = true
    disk_type    = "pd-ssd"
  }

  dynamic "disk" {
    for_each = var.use_local_ssd ? [1] : []
    content {
      device_name  = "executor-pd"
      interface    = "NVME"
      disk_type    = "local-ssd"
      type         = "SCRATCH"
      disk_size_gb = 375
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id
    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {
        # I believe this is the default.
        network_tier = "PREMIUM"
      }
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh.tpl", {
    environment_variables = {
      "EXECUTOR_DOCKER_REGISTRY_MIRROR"     = var.docker_registry_mirror
      "DOCKER_REGISTRY_NODE_EXPORTER_URL"   = var.docker_registry_mirror_node_exporter_url
      "SOURCEGRAPH_EXTERNAL_URL"            = var.sourcegraph_external_url
      "SOURCEGRAPH_EXECUTOR_PROXY_PASSWORD" = var.sourcegraph_executor_proxy_password
      "EXECUTOR_MAXIMUM_NUM_JOBS"           = var.maximum_num_jobs
      "EXECUTOR_JOB_NUM_CPUS"               = var.job_num_cpus != "" ? var.job_num_cpus : var.firecracker_num_cpus
      "EXECUTOR_JOB_MEMORY"                 = var.job_memory != "" ? var.job_memory : var.firecracker_memory
      "EXECUTOR_FIRECRACKER_DISK_SPACE"     = var.firecracker_disk_space
      "EXECUTOR_QUEUE_NAME"                 = var.queue_name
      "EXECUTOR_QUEUE_NAMES"                = local.queue_names
      "EXECUTOR_MAXIMUM_RUNTIME_PER_JOB"    = var.maximum_runtime_per_job
      "EXECUTOR_NUM_TOTAL_JOBS"             = var.num_total_jobs
      "EXECUTOR_MAX_ACTIVE_TIME"            = var.max_active_time
      "EXECUTOR_USE_FIRECRACKER"            = var.use_firecracker
      "EXECUTOR_DOCKER_AUTH_CONFIG"         = var.docker_auth_config
      "USE_LOCAL_SSD"                       = var.use_local_ssd
      "PRIVATE_CA_CERTIFICATE"              = var.private_ca_cert_path != "" ? file(var.private_ca_cert_path) : ""
    }
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_id" "compute_instance_group_executor" {
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 4
}
resource "google_compute_instance_group_manager" "executor" {
  name = local.resource_values.compute_instance_group_manager.name
  zone = var.zone

  version {
    instance_template = google_compute_instance_template.executor-instance-template.id
    name              = "primary"
  }

  base_instance_name = local.resource_values.compute_instance_group_manager.base_instance_name

  update_policy {
    max_surge_percent = 100
    minimal_action    = "REPLACE"
    type              = "PROACTIVE"
  }

  lifecycle {
    ignore_changes = [
      target_size
    ]
  }
}

resource "google_compute_autoscaler" "executor-autoscaler" {
  # Need to use the beta provider here, some fields are otherwise not supported.
  provider = google-beta
  name     = local.resource_values.compute_autoscaler.name
  zone     = var.zone
  target   = google_compute_instance_group_manager.executor.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 300

    metric {
      name = "custom.googleapis.com/executors/queue/size"
      # TODO: Isn't there an AND missing here?
      filter = "resource.type = \"global\" metric.labels.queueName = \"${local.metric_queue_val}\" AND metric.labels.environment = \"${var.metrics_environment_label}\""

      # 1 instance per N queued jobs.
      single_instance_assignment = var.jobs_per_instance_scaling
    }
  }
}

resource "random_id" "firewall_rule_prefix" {
  count       = var.randomize_resource_names ? 1 : 0
  byte_length = 4
}
resource "google_compute_firewall" "executor-ssh-access" {
  name        = local.resource_values.compute_firewall.name
  network     = var.network_id
  target_tags = local.resource_values.compute_firewall.target_tags

  # Google IAP source range.
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
