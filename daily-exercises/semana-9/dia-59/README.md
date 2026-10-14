# Dia 59: NoSQL Database Engineering with Amazon DynamoDB on LocalStack

## 1. Technical Overview and Objective

The objective of Day 59 is to master cloud-native NoSQL database modeling and operations using Amazon DynamoDB on LocalStack. Traditional relational databases (like PostgreSQL) face scaling bottlenecks under massive write throughput without complex sharding. DynamoDB provides single-digit millisecond latency at any scale through a fully managed, distributed key-value and document store. Designing high-performance DynamoDB applications requires mastering partition keys, composite primary keys, Global Secondary Indexes (GSIs), and understanding the cost disparity between `Query` and `Scan` operations.

Key goals:
- Understand DynamoDB data modeling: Partition Key (HASH) vs Sort Key (RANGE).
- Create a high-throughput table for storing vote audit logs with On-Demand billing.
- Create a Global Secondary Index (GSI) to enable secondary access patterns.
- Configure Time-To-Live (TTL) for automated record pruning.
- Compare performance and cost characteristics of `Query` vs `Scan` operations.

---

## 2. Architecture and DynamoDB Data Modeling

### 2.1 Table Schema and Key Distribution

```
+-------------------------------------------------------------------------+
| DYNAMODB TABLE: VotesAudit (Billing: PAY_PER_REQUEST / On-Demand)       |
+-------------------------------------------------------------------------+
| PRIMARY KEY: Composite (Partition Key + Sort Key)                       |
|  - Partition Key (PK / HASH):  voter_id (String - Even distribution)    |
|  - Sort Key      (SK / RANGE): timestamp (Number - Epoch ms ordering)   |
+------------------------------------+------------------------------------+
| ATTRIBUTES                         | GLOBAL SECONDARY INDEX (GSI)       |
|  - option: "a" | "b"               |  GSI Name: OptionIndex             |
|  - client_ip: "192.168.1.10"       |  - GSI PK: option                  |
|  - ttl: 1774828800 (Epoch seconds) |  - GSI SK: timestamp               |
+------------------------------------+------------------------------------+
```

### 2.2 Query vs Scan Operations Comparison

```
+-----------------------------------+-------------------------------------+
| QUERY OPERATION                   | SCAN OPERATION                      |
+-----------------------------------+-------------------------------------+
| - Requires Partition Key lookup   | - Reads EVERY item in entire table  |
| - Fast: O(1) partition targeting  | - Slow: O(N) linear table traversal |
| - Cost efficient: Read Units      | - Expensive: Consumes Read Units for|
|   consumed only for returned rows |   all rows before applying filter   |
| - Recommended for all production  | - Anti-pattern in high-throughput   |
|   application access paths        |   production applications           |
+-----------------------------------+-------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative DynamoDB Table Creation (`create-table.json`)

```json
{
  "TableName": "VotesAudit",
  "KeySchema": [
    { "AttributeName": "voter_id", "KeyType": "HASH" },
    { "AttributeName": "timestamp", "KeyType": "RANGE" }
  ],
  "AttributeDefinitions": [
    { "AttributeName": "voter_id", "AttributeType": "S" },
    { "AttributeName": "timestamp", "AttributeType": "N" },
    { "AttributeName": "option", "AttributeType": "S" }
  ],
  "GlobalSecondaryIndexes": [
    {
      "IndexName": "OptionIndex",
      "KeySchema": [
        { "AttributeName": "option", "KeyType": "HASH" },
        { "AttributeName": "timestamp", "KeyType": "RANGE" }
      ],
      "Projection": {
        "ProjectionType": "ALL"
      }
    }
  ],
  "BillingMode": "PAY_PER_REQUEST"
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Create DynamoDB table on LocalStack
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
  --cli-input-json file://create-table.json

# 2. Configure Time-To-Live (TTL) on the 'ttl' attribute
aws --endpoint-url=http://localhost:4566 dynamodb update-time-to-live \
  --table-name VotesAudit \
  --time-to-live-specification "Enabled=true,AttributeName=ttl"

# 3. Insert items (PutItem)
aws --endpoint-url=http://localhost:4566 dynamodb put-item \
  --table-name VotesAudit \
  --item '{
    "voter_id": {"S": "usr_9481"},
    "timestamp": {"N": "1774828000"},
    "option": {"S": "a"},
    "client_ip": {"S": "192.168.1.15"},
    "ttl": {"N": "1777420000"}
  }'

aws --endpoint-url=http://localhost:4566 dynamodb put-item \
  --table-name VotesAudit \
  --item '{
    "voter_id": {"S": "usr_9481"},
    "timestamp": {"N": "1774828100"},
    "option": {"S": "b"},
    "client_ip": {"S": "192.168.1.15"},
    "ttl": {"N": "1777420000"}
  }'
```

---

## 5. Real-World Verification Methods

```bash
# 1. Execute targeted Query by Partition Key
aws --endpoint-url=http://localhost:4566 dynamodb query \
  --table-name VotesAudit \
  --key-condition-expression "voter_id = :v" \
  --expression-attribute-values '{":v": {"S": "usr_9481"}}'

# 2. Execute Query against Global Secondary Index (OptionIndex)
aws --endpoint-url=http://localhost:4566 dynamodb query \
  --table-name VotesAudit \
  --index-name OptionIndex \
  --key-condition-expression "#opt = :o" \
  --expression-attribute-names '{"#opt": "option"}' \
  --expression-attribute-values '{":o": {"S": "a"}}'

# 3. Clean up table
aws --endpoint-url=http://localhost:4566 dynamodb delete-table --table-name VotesAudit
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Hot Partitions and Key Skew**:
   - Risk: Choosing a low-cardinality partition key (e.g., using `option` as the primary PK) directs all writes to a single physical storage partition, causing write throttling.
   - Solution: Ensure the Partition Key has high cardinality (UUIDs, user IDs, device hashes) to distribute I/O evenly across internal storage nodes.

2. **Reserved Keywords in Queries**:
   - Issue: Querying fails with `ValidationException: Attribute name is a reserved keyword` when referencing fields like `timestamp`, `status`, or `option`.
   - Solution: Use Expression Attribute Names (`#opt: "option"`, `#ts: "timestamp"`) in the query payload to escape reserved keywords safely.

3. **TTL Deletion Asynchrony**:
   - Lesson: Items whose TTL timestamp has passed are not purged instantly; DynamoDB purges them in the background typically within 48 hours without consuming write capacity units. Applications requiring hard expiration filters must include client-side timestamp checks in query filters.
