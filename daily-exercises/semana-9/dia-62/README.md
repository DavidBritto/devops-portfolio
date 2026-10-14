# Dia 62: Infrastructure as Code with Terraform and LocalStack AWS Provider

## 1. Technical Overview and Objective

The objective of Day 62 is to manage cloud infrastructure declaratively using HashiCorp Terraform targeting the LocalStack emulator. While manual CLI commands are useful for one-off exploration, enterprise cloud infrastructure must be provisioned through version-controlled, declarative code. By configuring the standard Terraform AWS Provider with custom service endpoint redirections, engineering teams can use identical Terraform modules and HCL syntax for local development, staging tests, and real AWS production deployments.

Key goals:
- Configure the Terraform AWS Provider to route API calls to LocalStack (`http://localhost:4566`).
- Configure provider flags: `s3_use_path_style`, `skip_credentials_validation`, `skip_metadata_api_check`, and `skip_requesting_account_id`.
- Provision S3 buckets, DynamoDB tables, and SQS queues using declarative HCL resources.
- Manage Terraform state locally and understand remote state emulation on LocalStack S3.
- Execute full lifecycle automation: `terraform init`, `validate`, `plan`, `apply`, and `destroy`.

---

## 2. Architecture and Terraform LocalStack Integration

### 2.1 Provider Redirection Topology

```
+-------------------------------------------------------------------------+
| TERRAFORM CLIENT ENGINE                                                 |
|  - main.tf (declares aws_s3_bucket, aws_dynamodb_table, aws_sqs_queue)  |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
| TERRAFORM AWS PROVIDER (hashicorp/aws)                                  |
|  - endpoints { s3 = "http://localhost:4566", dynamodb = ... }          |
|  - s3_use_path_style = true                                             |
|  - skip_credentials_validation = true                                   |
+------------------------------------+------------------------------------+
                                     | Redirected HTTP/REST Calls
                                     v
+-------------------------------------------------------------------------+
| LOCALSTACK CONTAINER (Port 4566)                                        |
|  - Emulates AWS Cloud APIs without network egress or AWS billing         |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Terraform Specification (`main.tf`)

```hcl
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
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    sns      = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

# 1. Managed S3 Bucket for voting exports
resource "aws_s3_bucket" "audit_bucket" {
  bucket = "roxs-voting-terraform-audit"
}

# 2. Managed DynamoDB NoSQL Table
resource "aws_dynamodb_table" "votes_table" {
  name         = "TerraformVotes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "voter_id"
  range_key    = "timestamp"

  attribute {
    name = "voter_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }
}

# 3. Managed SQS Queue
resource "aws_sqs_queue" "voting_queue" {
  name                      = "terraform-voting-queue"
  message_retention_seconds = 86400
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Navigate to working directory
mkdir -p /tmp/tf-localstack-lab && cd /tmp/tf-localstack-lab

# 2. Save HCL code to main.tf
cat <<EOF > main.tf
# (Insert HCL configuration from section 3.1)
EOF

# 3. Initialize working directory
terraform init

# 4. Validate configuration syntax
terraform validate

# 5. Generate and review execution plan
terraform plan -out=tfplan

# 6. Apply resources to LocalStack
terraform apply tfplan

# 7. Inspect state
terraform show
```

---

## 5. Real-World Verification Methods

```bash
# 1. Query LocalStack with AWS CLI to confirm Terraform created the S3 bucket
aws --endpoint-url=http://localhost:4566 s3 ls | grep roxs-voting-terraform-audit

# 2. Query LocalStack to confirm DynamoDB table was provisioned
aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name TerraformVotes

# 3. Destroy resources cleanly via Terraform
terraform destroy -auto-approve
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **The Necessity of `s3_use_path_style = true`**:
   - Issue: Terraform S3 operations fail with `Error: error creating S3 bucket: RequestError: send request failed`.
   - Reason: By default, the AWS provider uses virtual-hosted-style requests (`<bucket>.s3.amazonaws.com`). LocalStack cannot resolve `<bucket>.localhost` without custom DNS resolver configuration.
   - Solution: Set `s3_use_path_style = true` to force requests to format as `http://localhost:4566/<bucket>`.

2. **Skipping AWS Metadata API Checks**:
   - Issue: Terraform hangs for 30 seconds on `terraform init` or `plan` attempting to connect to `169.254.169.254`.
   - Cause: The provider attempts to discover EC2 instance metadata credentials by default.
   - Solution: Set `skip_metadata_api_check = true` and `skip_credentials_validation = true`.

3. **Parity Between LocalStack and Real AWS Modules**:
   - Best Practice: Maintain identical Terraform module code for both environments. Use input variables for provider endpoint URLs (`var.aws_custom_endpoint`), passing empty strings for real AWS and `http://localhost:4566` during local integration tests.
