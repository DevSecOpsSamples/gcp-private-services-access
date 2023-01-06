provider "google" {
  project = var.project_id
  region  = var.region
}
module "project-services" {
  source     = "terraform-google-modules/project-factory/google//modules/project_services"
  version    = "~> 14.1"
  project_id = var.project_id
  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
  # DO NOT REMOVE disalbe* options. APIs will be DISABLED if you destroy resources after removing below, effect your services:
  disable_services_on_destroy = false
  disable_dependent_services  = false
}

locals {
  vpc-name-without-stage = "gke-networktest"

  # CIDR: 172.19.0.0/16, 172.19.0.0/20 -172.19.15.255, 172.19.32.0/20-172.19.47.255
  b-class = "172.19"
  # b-class = "172.20"
}
resource "google_compute_network" "this" {
  provider                = google
  name                    = format("%s-%s", local.vpc-name-without-stage, var.stage)
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "this" {
  name                     = format("%s-subnet1-%s", local.vpc-name-without-stage, var.stage)
  ip_cidr_range            = format("%s.0.0/20", local.b-class)
  region                   = var.region
  network                  = google_compute_network.this.name
  private_ip_google_access = true
}
resource "google_compute_subnetwork" "subnet2" {
  name                     = format("%s-subnet2", google_compute_network.this.name)
  ip_cidr_range            = format("%s.32.0/20", local.b-class)
  region                   = var.region
  network                  = google_compute_network.this.name
  private_ip_google_access = true
}

resource "google_compute_global_address" "vpc-peering" {
  name          = format("managed-service-%s", var.stage)
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = format("%s.128.0", local.b-class)
  prefix_length = 20
  network       = google_compute_network.this.id
}
resource "google_service_networking_connection" "vpc-peering" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.vpc-peering.name]
  depends_on              = [google_compute_global_address.vpc-peering]
}
resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering              = google_service_networking_connection.vpc-peering.peering
  network              = google_compute_network.this.name
  import_custom_routes = true
  export_custom_routes = true
}

#
# Testing for PRIVATE_SERVICE_CONNECT type resource is not yet completed
#
# provider "google-beta" {
#   project = var.project_id
#   region  = var.region
# }
# 
# IMPORTANT - provider for the PRIVATE_SERVICE_CONNECT is 'google-beta'
# resource "google_compute_network" "google-beta" {
#   provider                = google-beta
#   name                    = format("gke-networktest-%s", var.stage)
#   auto_create_subnetworks = false
#   mtu                     = 1460
# }
# resource "google_compute_global_address" "psc" {
#   provider     = google-beta
#   name         = "psc-managed-service"
#   address_type = "INTERNAL"
#   purpose      = "PRIVATE_SERVICE_CONNECT"
#   network      = google_compute_network.this.id
#   address      = "172.19.144.1"
#   # prefix_length = 20 
#   # resource.prefixLength': '20'. The field cannot be specified for reserving internal IP Addresses. Please unset the field and retry the operation
#   # This field is not applicable to addresses with addressType=EXTERNAL, or addressType=INTERNAL when purpose=PRIVATE_SERVICE_CONNECT
#    # address      = "172.19.144.1/32" # Invalid value for field 'resource.address': '172.19.144.1/32'. Must be a valid IP address.
# }

data "terraform_remote_state" "this" {
  backend   = "gcs"
  workspace = var.stage
  config = {
    bucket = var.backend_bucket
    prefix = format("vpc/%s", format("gke-networktest-%s", var.stage))
  }
}