provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_network" "this" {
  name = "gke-networktest-${var.stage}"
}

data "google_compute_global_address" "this" {
  name = format("managed-service-%s", var.stage)
}

resource "google_redis_instance" "this" {
  name               = "redis-directpeering-${var.stage}"
  memory_size_gb     = 1
  redis_version      = "REDIS_6_X"
  tier               = "BASIC"
  connect_mode       = "DIRECT_PEERING"
  authorized_network = data.google_compute_network.this.id
}

data "terraform_remote_state" "this" {
  backend   = "gcs"
  workspace = var.stage
  config = {
    bucket = var.backend_bucket
    prefix = format("memorystore/%s", "redis-${var.stage}")
  }
}