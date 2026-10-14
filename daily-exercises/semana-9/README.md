# Semana 9: Cloud Engineering with LocalStack, AWS Core Services, and Terraform Integration

## Overview

Week 9 explores cloud engineering, serverless architectures, and Infrastructure as Code using LocalStack. Developing and testing cloud infrastructure directly on live public cloud providers (such as AWS) incurs ongoing billing, introduces security risks from leaked credentials, and slows developer feedback loops due to provisioning latency. LocalStack provides a fully functional local AWS cloud emulator, enabling engineers to develop, provision with Terraform, and test S3, DynamoDB, SQS, SNS, and Lambda workflows entirely offline.

---

## Technical Curriculum Breakdown

| Day | Topic | Key Concepts and Deliverables |
|---|---|---|
| Dia 57 | LocalStack & Cloud Emulation | LocalStack architecture, Docker deployment, AWS CLI / `awslocal` wrapper |
| Dia 58 | Amazon S3 Storage Operations | Object storage, versioning, bucket policies, lifecycle rules, presigned URLs |
| Dia 59 | Amazon DynamoDB NoSQL | Key-value/document storage, partition/sort keys, Global Secondary Indexes |
| Dia 60 | AWS Lambda & Serverless Compute | Function runtimes, ZIP packaging, event-driven compute, IAM roles |
| Dia 61 | Event-Driven Cloud Architecture | S3 object created events triggering Lambda, SQS dead-letter queues |
| Dia 62 | Terraform + LocalStack Integration | AWS Provider custom endpoints configuration, state locking, module reuse |
| Dia 63 | Week 9 Final Challenge | Serverless voting record audit pipeline on LocalStack provisioned via Terraform |

---

## Directory Structure

```
daily-exercises/semana-9/
├── README.md           # Semana 9 module overview and cloud roadmap
├── dia-57/README.md    # LocalStack architecture and setup
├── dia-58/README.md    # AWS S3 bucket policies and object management
├── dia-59/README.md    # DynamoDB NoSQL tables and indexing
├── dia-60/README.md    # Serverless computing with AWS Lambda
├── dia-61/README.md    # Event-driven cloud integrations (S3 -> SQS -> Lambda)
├── dia-62/README.md    # Terraform AWS provider integration with LocalStack
└── dia-63/README.md    # Week 9 Capstone: Complete serverless cloud stack
```
