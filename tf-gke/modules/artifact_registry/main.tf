resource "google_artifact_registry_repository" "test-repo" {
  location      = var.region
  repository_id = "test-repository"
  description   = "test docker repository"
  format        = "DOCKER"
}