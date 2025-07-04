provider "aws" {
  region = "us-west-2"
}

# ✅ Create S3 bucket to hold state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-eks-terraform-state-sshailesh49"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "Terraform State Bucket"
    Environment = "dev"
  }
}

# ✅ Create DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
    Environment = "dev"
  }
}
