terraform {
  required_version = ">= 1.8.3"
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/TerraformPowerUserRole"
  }
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_id}:role/TerraformPowerUserRole"
  }
}

terraform {
  backend "s3" {
    key                    = "moleculer.tfstate"
    skip_region_validation = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50.0"
    }
  }
}
