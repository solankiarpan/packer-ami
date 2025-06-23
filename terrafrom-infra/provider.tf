terraform {
  #required_version = ">= 1.5.2, <= 1.6.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.22.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}