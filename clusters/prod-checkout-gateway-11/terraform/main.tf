terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "gke_cluster" {
  source = "../../../terraform/modules/gke-cluster"

  project_id   = var.project_id
  cluster_name = var.cluster_name
  zone         = var.zone
  machine_type = var.machine_type
  node_count   = var.node_count
}
