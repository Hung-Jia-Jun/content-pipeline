locals {
  pipeline_service_account = "${var.pipeline_service_account}@${var.project_id}${var.sa_suffix}"
}

resource "google_storage_bucket" "content-pipeline-file" {
  name          = "content-pipeline-file"
  location      = "us-east1"
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.content-pipeline-file.name
  role = "roles/storage.objectCreator"
  member = "serviceAccount:${local.pipeline_service_account}"
}
