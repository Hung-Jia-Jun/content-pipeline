variable "project_id" {
  type        = string
  default     = "test-project-414912"
}

variable "cluster_name" {
  default     = "gke-test-cluster"
}

variable "gcp_region" {
  default     = "us-east1"
}
variable "gke_region" {
  default     = "us-east1"
}

variable "network" {
  default     = "gke-network"
}

variable "subnetwork" {
  default     = "gke-subnet"
}

variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-range-pods"
}

variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "ip-range-svc"
}


variable "gke_nodepools" {
  description = "Map of nodepool to configuration."
  type        = map(any)

  default = {
    default-node-pool = {
      name                      = "default-node-pool"
      machine_type              = "n1-standard-1"
      node_locations            = [
        "us-east1-b",
        "us-east1-c",
        "us-east1-d"
      ]
      min_count                 = 0
      max_count                 = 1
      initial_node_count        = 0
      disk_size_gb              = 10
      taint                     = []
    },
    kafka-node-pool = {
        name                      = "kafka-node-pool"
        machine_type              = "n1-standard-2"
        node_locations            = [
          "us-east1-b",
          "us-east1-c",
          "us-east1-d"
        ]
        min_count                 = 0
        max_count                 = 1
        initial_node_count        = 0
        disk_size_gb              = 15
        taint                     = [
          {
            key    = "dedicated"
            value  = "kafka-node-pool"
            effect = "NO_SCHEDULE"
          },
        ]
    }
    es-node-pool = {
      name                      = "es-node-pool"
      machine_type              = "n1-standard-2"
      node_locations            = [
        "us-east1-b",
        "us-east1-c",
        "us-east1-d"
      ]
      min_count                 = 0
      max_count                 = 2
      initial_node_count        = 0
      disk_size_gb              = 15
      taint                     = [
        {
          key    = "dedicated"
          value  = "es-node-pool"
          effect = "NO_SCHEDULE"
        },
      ]
    },
  }
}