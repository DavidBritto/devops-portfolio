terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    sqs      = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "voting_storage" {
  bucket = "voting-app-terraform-local"
}

resource "aws_s3_bucket_versioning" "storage_versioning" {
  bucket = aws_s3_bucket.voting_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_sqs_queue" "voting_dlq" {
  name                      = "voting-dead-letter-queue"
  message_retention_seconds = 86400
}
