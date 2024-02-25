terraform {
  required_version = ">=1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.40.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
}