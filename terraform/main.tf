provider "aws" {
  region = "ap-south-1a"
  alias = "ap-south"
}

terraform {
  required_providers {
    aws = {
        version = ""
    }
  }
}