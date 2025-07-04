terraform {
  backend "s3" {
    bucket         = "my-eks-terraform-state-sshailesh49"     # ✅ S3 bucket name
    key            = "env/dev/terraform.tfstate"  # 🗂️ file path in S3
    region         = "us-west-2"
    dynamodb_table = "terraform-lock-table"       # 🔐 locking for concurrency
    encrypt        = true
  }
}
