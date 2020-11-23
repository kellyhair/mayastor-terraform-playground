terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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

provider "aws" {
  region  = var.region
  version = "~> 3.15.0"
}

provider "kubernetes" {
  config_path = module.cluster.kubeconfig
  version     = "~> 1.13.3"
}

provider "null" {
  version = "~> 3.0.0"
}

provider "random" {
  version = "~> 3.0.0"
}
