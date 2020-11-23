terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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

provider "aws" {
  region  = var.aws_region
  version = "~> 3.15.0"
}

provider "null" {
  version = "~> 3.0.0"
}

provider "random" {
  version = "~> 3.0.0"
}
