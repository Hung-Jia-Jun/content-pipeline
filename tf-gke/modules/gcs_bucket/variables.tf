variable "pipeline_service_account" {
  type        = string
  default = "test-project-service-account"
}

variable "project_id" {
  type        = string
}

variable "sa_suffix" {
  type        = string
  default     = ".iam.gserviceaccount.com" 
}