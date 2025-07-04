terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                  = "ap-south-1" # Mumbai Region
  #access_key              = var.aws_access_key    # Optional: use only in local/dev
  #secret_key              = var.aws_secret_key    # Optional: use only in local/dev
 # allowed_account_ids     = [var.account_id]
}
