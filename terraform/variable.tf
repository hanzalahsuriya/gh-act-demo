variable "project_id" {
  description = "GCP Project ID for the environment"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}
