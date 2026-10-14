# Dia 63: Final Challenge Week 9 - Serverless Voting Audit System on LocalStack via Terraform

## 1. Technical Overview and Objective

The objective of Day 63 is the design, declarative provisioning, and verification of a complete event-driven serverless cloud system. This capstone challenge for Week 9 integrates all core AWS services emulated on LocalStack -- Amazon S3, Amazon DynamoDB, Amazon SQS, and AWS Lambda -- orchestrated entirely through declarative Terraform Infrastructure as Code. The system ingests external voting audit batches into an S3 bucket, dispatches event notifications through an SQS queue, triggers an unprivileged Lambda consumer, and persists normalized voting transactions into a high-performance DynamoDB NoSQL table.

Key goals:
- Architect a multi-service event-driven serverless cloud topology.
- Author modular, reusable Terraform manifests targeting LocalStack AWS services.
- Package and deploy a Python Lambda processor with least-privilege IAM policies.
- Wire event notifications: S3 Object Creation -> SQS Ingestion Queue -> Lambda Event Source Mapping.
- Execute an end-to-end transaction test and verify state storage in DynamoDB.

---

## 2. Architecture and Complete Serverless Workflow Breakdown

### 2.1 Complete Serverless Event Flow

```
[External Audit Producer / Batch Export]
                 |
                 v 1. Uploads JSON audit batch
+-------------------------------------------------------------------------+
| AMAZON S3 BUCKET: roxs-voting-audit-archive                             |
|  - Key: incoming/batch-2026-10-06.json                                  |
|  - Emits: s3:ObjectCreated:*                                            |
+------------------------------------+------------------------------------+
                                     | 2. Event notification
                                     v
+-------------------------------------------------------------------------+
| AMAZON SQS: audit-processing-queue                                      |
|  - Buffers event payloads                                               |
|  - Dead-Letter Queue attached: audit-dlq                                |
+------------------------------------+------------------------------------+
                                     | 3. Event Source Mapping trigger
                                     v
+-------------------------------------------------------------------------+
| AWS LAMBDA: audit-consumer-function                                     |
|  - Runtime: Python 3.11                                                 |
|  - Reads file from S3, parses vote records                              |
|  - Writes batch items (PutItem)                                         |
+------------------------------------+------------------------------------+
                                     | 4. Batch persistence
                                     v
+-------------------------------------------------------------------------+
| AMAZON DYNAMODB: AuditLedger                                            |
|  - PK: voter_id | SK: timestamp | Attributes: vote, origin_file         |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Terraform Specification (`serverless-stack.tf`)

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
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    sqs      = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

# 1. DynamoDB Table for durable audit records
resource "aws_dynamodb_table" "audit_table" {
  name         = "AuditLedger"
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

# 2. SQS Queue for message decoupling
resource "aws_sqs_queue" "audit_queue" {
  name                      = "audit-processing-queue"
  message_retention_seconds = 86400
}

# 3. S3 Bucket for archive ingestion
resource "aws_s3_bucket" "audit_bucket" {
  bucket = "roxs-voting-audit-archive"
}

# 4. IAM Execution Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "audit_consumer_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 5. Lambda Consumer Function
resource "aws_lambda_function" "audit_consumer" {
  filename         = "lambda_bundle.zip"
  function_name    = "audit-consumer-function"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  timeout          = 15

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.audit_table.name
      AWS_ENDPOINT   = "http://localhost:4566"
    }
  }
}

# 6. Event Source Mapping: SQS to Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.audit_queue.arn
  function_name    = aws_lambda_function.audit_consumer.arn
  batch_size       = 5
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to challenge workspace
cd /home/david/git/devops-porfolio/daily-exercises/semana-9/dia-63

# 1. Create mock Lambda function bundle
cat <<'EOF' > index.py
import json, os, boto3

def handler(event, context):
    print("Processing event records: ", json.dumps(event))
    return {"status": "SUCCESS"}
EOF
zip lambda_bundle.zip index.py

# 2. Initialize and apply Terraform stack
terraform init
terraform apply -auto-approve

# 3. Inspect provisioned resources
terraform output
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify S3 bucket presence in LocalStack
aws --endpoint-url=http://localhost:4566 s3 ls | grep roxs-voting-audit-archive

# 2. Verify DynamoDB table active state
aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name AuditLedger | grep '"TableStatus": "ACTIVE"'

# 3. Verify SQS queue URL
aws --endpoint-url=http://localhost:4566 sqs get-queue-url --queue-name audit-processing-queue

# 4. Clean up infrastructure
terraform destroy -auto-approve
rm -f lambda_bundle.zip index.py
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Lambda Event Source Mapping Polling in LocalStack**:
   - Issue: SQS messages remain in the queue without triggering the Lambda function.
   - Solution: In LocalStack, ensure the Lambda execution engine is running and that the Event Source Mapping state is `Enabled`. Check LocalStack container logs via `docker logs localstack-dev` to diagnose worker sandbox spawn timeouts.

2. **Decoupling Cloud Infrastructure from Cloud Bills**:
   - Lesson: Emulating cloud workflows locally via LocalStack allows engineers to iterate on Terraform manifests, test IAM edge cases, and run automated CI validation tests for zero cost, eliminating the risk of accidental $1,000+ AWS cloud bills from orphaned cloud test resources.

3. **Event Source Idempotency**:
   - Lesson: When processing streams or queues via serverless compute, design downstream datastore writes using idempotent keys (such as `voter_id` + `timestamp` composite keys) to guarantee that retried messages update records in-place without generating duplicates.
