output "project_id" {
  value = var.project_id
}

output "stage" {
  value = var.stage
}

output "authorized_network" {
  value = google_redis_instance.this.authorized_network
}

output "redis_host" {
  value = google_redis_instance.this[*].host
}

output "read_endpoint" {
  value = google_redis_instance.this[*].read_endpoint
}