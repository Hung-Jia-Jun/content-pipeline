module "gke_cluster" {
  source = "./modules/gke/"
  project_id = var.project_id
}

module "composer" {
  source = "./modules/composer/"
  project_id = var.project_id
}

module "artifact_registry" {
  source = "./modules/artifact_registry/"
  region = "us-east1"
}

module "gcs_bucket" {
  source = "./modules/gcs_bucket/"
}