# Dia 60: Serverless Computing with AWS Lambda on LocalStack

## 1. Technical Overview and Objective

The objective of Day 60 is to master serverless application deployment using AWS Lambda on LocalStack. Serverless architectures eliminate the operational overhead of provisioning, patching, and scaling underlying virtual machines or container hosts. Code executes purely on demand in ephemeral execution environments managed by the cloud platform, scaling automatically from zero to thousands of concurrent requests while billing only for milliseconds of compute used.

Key goals:
- Understand the AWS Lambda execution environment lifecycle: **Init Phase** (cold start), **Invoke Phase**, and **Shutdown Phase**.
- Package and deploy serverless functions using ZIP archives.
- Configure IAM execution roles with least privilege permissions.
- Inject runtime configuration via environment variables.
- Execute and measure both synchronous (`RequestResponse`) and asynchronous (`Event`) function invocations.

---

## 2. Architecture and Serverless Lifecycle Breakdown

### 2.1 Lambda Cold Start and Invocation Lifecycle

```
[Invocation Request]
        |
        v (If no warm execution sandbox exists)
+-------------------------------------------------------------------------+
| INIT PHASE (Cold Start - Incurred once per sandbox instance)            |
|  1. Download function ZIP artifact                                      |
|  2. Spin up MicroVM / container sandbox                                 |
|  3. Initialize runtime (Python 3.11 engine)                             |
|  4. Run outer function initialization code (database clients, SDKs)    |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
| INVOKE PHASE (Warm Execution - Repeats per subsequent request)          |
|  1. Invoke handler function: def handler(event, context)                |
|  2. Process event payload                                               |
|  3. Return response object                                              |
+------------------------------------+------------------------------------+
                                     |
                                     v (After prolonged idle timeout)
+-------------------------------------------------------------------------+
| SHUTDOWN PHASE                                                          |
|  - Free execution environment resources                                 |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Serverless Python Function Code (`handler.py`)

```python
import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    environment = os.getenv("ENVIRONMENT", "dev")

    # Extract voting payload
    vote_choice = event.get("vote", "unknown")
    voter_id = event.get("voter_id", "anonymous")

    response_payload = {
        "status": "PROCESSED",
        "environment": environment,
        "voter_id": voter_id,
        "recorded_vote": vote_choice,
        "request_id": context.aws_request_id if hasattr(context, "aws_request_id") else "mock-id"
    }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(response_payload)
    }
```

### 3.2 IAM Execution Role Policy (`trust-policy.json`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Create a workspace directory
mkdir -p /tmp/lambda-lab && cd /tmp/lambda-lab

# 2. Package function code into ZIP archive
cat <<EOF > handler.py
# (Use handler.py contents from section 3.1)
EOF
zip function.zip handler.py

# 3. Create IAM execution role on LocalStack
aws --endpoint-url=http://localhost:4566 iam create-role \
  --role-name LambdaBasicExecutionRole \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

# 4. Deploy the Lambda function
aws --endpoint-url=http://localhost:4566 lambda create-function \
  --function-name ProcessVote \
  --runtime python3.11 \
  --role arn:aws:iam::000000000000:role/LambdaBasicExecutionRole \
  --handler handler.lambda_handler \
  --zip-file fileb://function.zip \
  --environment Variables="{ENVIRONMENT=production}" \
  --timeout 10 \
  --memory-size 128
```

---

## 5. Real-World Verification Methods

```bash
# 1. Execute synchronous invocation (RequestResponse)
aws --endpoint-url=http://localhost:4566 lambda invoke \
  --function-name ProcessVote \
  --payload '{"voter_id": "usr_102", "vote": "a"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# 2. Inspect returned execution response
cat response.json | jq .

# 3. Clean up function
aws --endpoint-url=http://localhost:4566 lambda delete-function --function-name ProcessVote
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Cold Starts and Connection Re-use**:
   - Issue: Initializing database connections inside `lambda_handler()` reconnects on every request, adding 200ms latency and exhausting DB connection pools.
   - Solution: Initialize database clients, SDK objects, and HTTP connection pools outside the handler in global scope. Warm execution sandboxes reuse existing connections across invocations.

2. **Payload Base64 Encoding in AWS CLI v2**:
   - Issue: `lambda invoke` fails with `Invalid base64: ...`.
   - Cause: AWS CLI v2 expects payload parameters as base64 by default.
   - Solution: Pass `--cli-binary-format raw-in-base64-out` when passing raw JSON payloads in AWS CLI v2.

3. **Memory Sizing vs CPU Allocation**:
   - Note: In AWS Lambda, you do not configure CPU cores directly; CPU allocation scales proportionally with memory size. Assigning 1,769 MB of RAM grants the equivalent of 1 full vCPU.
