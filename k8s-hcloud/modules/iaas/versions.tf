terraform {
  required_providers {
    hcloud = {
      source = "terraform-providers/hcloud"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 0.13"
}
