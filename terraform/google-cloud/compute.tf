locals {
  envs = [
    {
      name = "UPTIME_KUMA_CLOUDFLARED_TOKEN"
      value = cloudflare_tunnel.uptime-kuma.tunnel_token
    }
  ]

  config_sha = sha1("${join("", local.envs.*.value)}-${local.image}")
  image    = "ghcr.io/mchestr/uptime-kuma:${var.tag}"
  zone     = var.zone
}

module "uptime-kuma" {
  source  = "terraform-google-modules/container-vm/google"
  version = "3.1.1"

  container = {
    image = local.image
    env = local.envs
    volumeMounts = [{
        mountPath = "/app/data"
        name      = "data-disk-0"
        readOnly  = false
    }]
  }

  volumes = [{
    name = "data-disk-0"
    gcePersistentDisk = {
      pdName = "data-disk-0"
      fsType = "ext4"
    }
  }]

  restart_policy = "Always"
}

resource "google_service_account" "default" {
  account_id   = "uptimekuma-sa"
  display_name = "Service Account"
}

resource "google_compute_disk" "pd" {
  project = var.project_id
  name    = "uptime-kuma-data-disk"
  zone    = local.zone
  size    = 10
}

resource "google_compute_instance" "uptime-kuma" {
  project      = var.project_id
  name         = "uptime-kuma"
  machine_type = "e2-micro"
  zone         = local.zone
  description  = local.config_sha

  boot_disk {
    initialize_params {
      image = module.uptime-kuma.source_image
    }
  }

  attached_disk {
    source      = google_compute_disk.pd.self_link
    device_name = "data-disk-0"
    mode        = "READ_WRITE"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    gce-container-declaration = module.uptime-kuma.metadata_value
    google-logging-enabled    = "true"
    google-monitoring-enabled = "true"
  }

  labels = {
    container-vm = module.uptime-kuma.vm_container_label
  }

  service_account {
    email = google_service_account.default.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
