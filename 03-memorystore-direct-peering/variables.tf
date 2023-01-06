variable "project_id" {
  description = "The project ID to host the cluster in"
}

variable "region" {
  description = "The region to host the cluster in"
  default     = "us-central1"
}
variable "stage" {
  description = "stage"
  type        = string
  default     = "local"
}

variable "backend_bucket" {
  description = "backend bucket to save tfstate file"
  type        = string
  default     = ""
}