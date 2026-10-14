# Dia 61: Event-Driven Cloud Architectures - S3 Triggers, SQS Queues, and Dead-Letter Queues (DLQ)

## 1. Technical Overview and Objective

The objective of Day 61 is to implement decoupled, event-driven systems using Amazon S3, Simple Queue Service (SQS), and AWS Lambda on LocalStack. Tightly coupled synchronous architectures (e.g., service A waiting for service B's HTTP response) suffer from cascading failures: if downstream components slow down or crash, upstream services exhaust worker threads. Event-driven architectures invert this relationship: producers emit immutable event notifications asynchronously, message brokers buffer traffic surges, and consumer functions process items with automatic retries and Dead-Letter Queue (DLQ) isolation.

Key goals:
- Configure S3 Event Notifications to emit messages upon new object creation (`s3:ObjectCreated:*`).
- Deploy Amazon SQS standard message queues and configure Dead-Letter Queues (DLQs).
- Configure SQS queue policies allowing S3 event publishing.
- Attach AWS Lambda event source mappings to process queued messages in batches.
- Validate end-to-end event flow: File Upload -> S3 Event -> SQS Queue -> Lambda Processing.

---

## 2. Architecture and Asynchronous Event Pipeline Breakdown

### 2.1 Event Pipeline Architecture

```
+-------------------------------------------------------------------------+
| ASYNCHRONOUS EVENT-DRIVEN PIPELINE                                      |
+-------------------------------------------------------------------------+
| 1. S3 BUCKET: voting-audit-events                                       |
|    - File uploaded: s3://voting-audit-events/votes-batch-01.json        |
|    - Emits: s3:ObjectCreated:Put                                        |
+------------------------------------+------------------------------------+
                                     | Event Notification
                                     v
+-------------------------------------------------------------------------+
| 2. AMAZON SQS MESSAGE QUEUE: votes-ingest-queue                         |
|    - Decouples producer from consumer                                   |
|    - In-flight message buffering                                        |
|    - Redrive Policy: maxReceiveCount: 3                                 |
+------------------+---------------------------------+--------------------+
                   | Normal Delivery (Batch size: 5) | Failed 3x (Poison)
                   v                                 v
+------------------+--------------+   +--------------+--------------------+
| 3. CONSUMER LAMBDA FUNCTION    |   | 4. DEAD-LETTER QUEUE (DLQ)        |
|    - Processes vote records     |   |    - votes-dlq                    |
|    - Persists to DynamoDB       |   |    - Retains poison pills for    |
|    - Deletes message from SQS   |   |      forensic inspection         |
+---------------------------------+   +-----------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 SQS Redrive Policy with Dead-Letter Queue (`redrive-policy.json`)

```json
{
  "deadLetterTargetArn": "arn:aws:sqs:us-east-1:000000000000:votes-dlq",
  "maxReceiveCount": "3"
}
```

### 3.2 S3 Event Notification Configuration (`s3-notification.json`)

```json
{
  "QueueConfigurations": [
    {
      "QueueArn": "arn:aws:sqs:us-east-1:000000000000:votes-ingest-queue",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {
              "Name": "suffix",
              "Value": ".json"
            }
          ]
        }
      }
    }
  ]
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Create Dead-Letter Queue (DLQ)
aws --endpoint-url=http://localhost:4566 sqs create-queue \
  --queue-name votes-dlq

# 2. Create Primary Ingestion Queue attached to DLQ
aws --endpoint-url=http://localhost:4566 sqs create-queue \
  --queue-name votes-ingest-queue \
  --attributes '{
    "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:votes-dlq\",\"maxReceiveCount\":\"3\"}",
    "VisibilityTimeout": "30"
  }'

# 3. Create S3 Bucket
aws --endpoint-url=http://localhost:4566 s3api create-bucket \
  --bucket voting-audit-events

# 4. Bind S3 Event Notification to the SQS Queue
aws --endpoint-url=http://localhost:4566 s3api put-bucket-notification-configuration \
  --bucket voting-audit-events \
  --notification-configuration file://s3-notification.json
```

---

## 5. Real-World Verification Methods

```bash
# 1. Upload a JSON event file to S3
echo '{"vote_batch": [{"id": 1, "vote": "a"}]}' > test-batch.json
aws --endpoint-url=http://localhost:4566 s3 cp test-batch.json s3://voting-audit-events/test-batch.json

# 2. Verify that S3 automatically pushed an event notification into SQS
aws --endpoint-url=http://localhost:4566 sqs receive-message \
  --queue-url http://localhost:4566/000000000000/votes-ingest-queue \
  --max-number-of-messages 1

# 3. Purge test queues
aws --endpoint-url=http://localhost:4566 sqs purge-queue \
  --queue-url http://localhost:4566/000000000000/votes-ingest-queue
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Visibility Timeout vs Function Execution Timeout**:
   - Issue: Duplicate processing of messages in Lambda consumers.
   - Cause: If Lambda takes 20 seconds to process a batch, but SQS `VisibilityTimeout` is 15 seconds, SQS assumes the worker crashed and delivers the same messages to another consumer instance.
   - Rule: Always set SQS `VisibilityTimeout` to at least 6 times the consumer Lambda function timeout.

2. **Poison Pill Messages**:
   - Risk: A malformed JSON message crashes the consumer function. SQS retries indefinitely, halting queue processing (head-of-line blocking).
   - Solution: Configure a Dead-Letter Queue (DLQ) with `maxReceiveCount: 3`. After 3 failed attempts, SQS routes the poison pill to the DLQ, unblocking the main pipeline.

3. **At-Least-Once Delivery Semantics**:
   - Lesson: Standard SQS queues guarantee at-least-once delivery, meaning occasional duplicate messages will occur under network retries. Application processing logic must be designed to be **idempotent** (e.g. using unique transaction IDs in DynamoDB conditional writes).
