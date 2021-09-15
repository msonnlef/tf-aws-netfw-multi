terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.30"
    }
  }
  backend "s3" {
    bucket     = var.bucket
    lock_table = "terraform-lock"
    region     = var.region
    key        = var.key
  }
}
provider "aws" {
  region = var.region
  assume_role {
    role_arn     = var.role_arn
    session_name = var.repo
  }
}
