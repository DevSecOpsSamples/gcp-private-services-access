provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_network" "this" {
  name = "gke-networktest-${var.stage}"
}

resource "google_redis_instance" "this" {
  name               = "redis-psa-${var.stage}"
  memory_size_gb     = 1
  redis_version      = "REDIS_6_X"
  tier               = "BASIC"
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
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