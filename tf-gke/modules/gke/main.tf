locals {
  pipeline_namespace = "pipeline-app"
  pipeline_service_account = "pipeline-service-account"
}

resource "google_project_service" "config_connector" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}

module "gcp-network" {
  source  = "terraform-google-modules/network/google"
  version = ">= 7.5"

  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.gcp_region
    },
  ]

  secondary_ranges = {
    (var.subnetwork) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}
resource "google_service_account" "service_account" {
  account_id   = "test-project-service-account"
  display_name = "Service Account"
  project      = var.project_id
}

resource "google_service_account_key" "service_account" {
    service_account_id = google_service_account.service_account.account_id
}

resource "local_file" "service_account" {
    filename = "service_account.json"
    content  = base64decode(google_service_account_key.service_account.private_key)
}

resource "google_project_iam_member" "composer_service_account" {
  for_each = toset([
    "roles/artifactregistry.reader"
  ])
  role = each.key
  member   = "serviceAccount:${google_service_account.service_account.email}"
  project = var.project_id
}

# Grant the service account the ability to pull docker images from the Artifact Registry
resource "google_service_account_iam_binding" "bind_workload_identity_user" {
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.workloadIdentityUser"
  depends_on = [ google_container_cluster.primary ]
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${local.pipeline_namespace}/${local.pipeline_service_account}]",
  ]
}

resource "google_container_cluster" "primary" {
  name     = "gke-test-cluster"
  location = var.gke_region
  network                = module.gcp-network.network_name
  subnetwork             = module.gcp-network.subnets_names[0]
  depends_on = [ module.gcp-network ]
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }  
  addons_config {
    config_connector_config{
      enabled = true
    }
  }
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "nodes" {
  name       = each.key
  location   = "us-east1"
  cluster    = google_container_cluster.primary.name
  for_each = var.gke_nodepools
  node_locations = each.value.node_locations
  initial_node_count        = each.value.initial_node_count
  
  autoscaling{
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }
  node_config {
    preemptible               = false
    machine_type              = each.value.machine_type
    local_ssd_count           = 0
    spot                      = true
    disk_size_gb              = each.value.disk_size_gb
    disk_type                 = "pd-standard"
    image_type                = "COS_CONTAINERD"
    logging_variant           = "DEFAULT"
    dynamic "taint" {
      for_each = each.value.taint
      content {
        key    = taint.value["key"]
        value  = taint.value["value"]
        effect = taint.value["effect"]
      }
    }
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.service_account.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    labels = {
        selector_label = each.value.name
    }
  }
}

resource "kubernetes_secret" "artifactregistry" {
    type = "kubernetes.io/dockerconfigjson"

    metadata {

        name = "artifactregistry-image-pull-secret"
        namespace = "pipeline-app"

    }

    data = {

        ".dockerconfigjson" = jsonencode({

            auths = {

                "us-east1-docker.pkg.dev" = {
                    username = "_json_key"
                    password = base64decode(google_service_account_key.service_account.private_key)
                    email = "noreply@invalid.tld"
                    auth = base64encode("_json_key:${ base64decode(google_service_account_key.service_account.private_key) }")

                }

            }

        })

    }

}