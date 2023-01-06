provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "this" {
  name                     = format("gke-networktest-%s", var.stage)
  location                 = var.region
  network                  = format("gke-networktest-%s", var.stage)
  subnetwork               = format("gke-networktest-subnet1-%s", var.stage)
  remove_default_node_pool = true
  initial_node_count       = 1
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      maximum       = 4
    }
    resource_limits {
      resource_type = "memory"
      maximum       = 16
    }
  }
  workload_identity_config {
    workload_pool = format("%s.svc.id.goog", var.project_id)
  }
}

resource "google_container_node_pool" "nodes" {
  name       = google_container_cluster.this.name
  location   = var.region
  cluster    = google_container_cluster.this.name
  node_count = 1

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    labels = {
      stage = var.stage
    }
    spot         = true
    machine_type = "e2-medium"
    tags         = ["gke-node", google_container_cluster.this.name]
    metadata = {
      disable-legacy-endpoints = true
    }
  }
}

data "terraform_remote_state" "this" {
  backend   = "gcs"
  workspace = var.stage
  config = {
    bucket = var.backend_bucket
    prefix = format("gke/%s", google_container_cluster.this.name)
  }
}