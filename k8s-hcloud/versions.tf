terraform {
  required_providers {
    cloudflare = {
      source = "terraform-providers/cloudflare"
    }
    gitlab = {
      source = "terraform-providers/gitlab"
    }
    hcloud = {
      source = "terraform-providers/hcloud"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
}

provider "cloudflare" {
  version = "~> 2.6"
  # TODO/FIXME: it would be nicer to use api_token with limited access
  #
  # according to doc I can use api_token, however a token with access just to
  # zone in question doesn't seem to be able to filter zone_id using
  # data.cloudflare_zones
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

provider "gitlab" {
  token   = var.gitlab_token
  version = "~> 2.9"
}

provider "helm" {
  version = "~> 1.2"
  kubernetes {
    host        = "https://${module.iaas.master_ips.0}:6443/"
    config_path = module.iaas.k8s_admin_conf
  }
}

provider "hcloud" {
  token   = var.hcloud_token
  version = "~> 1.16"
}

provider "kubernetes" {
  config_path = module.iaas.k8s_admin_conf
  host        = "https://${module.iaas.master_ips.0}:6443/"
  version     = "~> 1.11"
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}
