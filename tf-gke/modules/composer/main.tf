provider "google-beta" {
  project = var.project_id
  region  = var.composer-region
}

resource "google_project_service" "composer_api" {
  provider = google-beta
  project = var.project_id
  service = "composer.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "composer_service_account" {
  provider = google-beta
  account_id   = "composer-service-account"
  display_name = "composer Service Account"
}

resource "google_project_iam_member" "composer_service_account" {
  for_each = toset([
    "roles/composer.worker",
    "roles/composer.ServiceAgentV2Ext"
  ])
  role = each.key
  member   = format("serviceAccount:%s", google_service_account.composer_service_account.email)
  project = var.project_id
}

# ref: https://cloud.google.com/composer/docs/composer-2/terraform-create-environments#agent-permissions
resource "google_service_account_iam_member" "composer_service_account" {
  provider = google-beta
  service_account_id = google_service_account.composer_service_account.name
  role = "roles/composer.ServiceAgentV2Ext"
  member = "serviceAccount:service-${var.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

resource "google_composer_environment" "test_environment" {
  provider = google-beta
  name = "test-environment"

  config {
    software_config {
      image_version = "composer-2.6.1-airflow-2.6.3"
    }

    node_config {
      service_account = google_service_account.composer_service_account.email
    }

  }
}