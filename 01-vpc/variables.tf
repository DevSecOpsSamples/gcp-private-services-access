variable "stage" {
  description = "stage"
  type        = string
  default     = "dev"
}
variable "ip_cidr_range" {
  description = "ip_cidr_range"
  type        = string
  default     = ""
}
variable "backend_bucket" {
  description = "backend bucket to save tfstate file"
  type        = string
  default     = ""
}