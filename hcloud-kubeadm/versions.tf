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

provider "hcloud" {
  token   = var.hcloud_token
  version = "~> 1.16"
}

provider "kubernetes" {
  config_path = module.k8s.k8s_admin_conf
  host        = "https://${module.k8s.master_ip}:6443/"
  version     = "~> 1.11"
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}
