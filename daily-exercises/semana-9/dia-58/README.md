# Dia 58: Object Storage with Amazon S3 - Policies, Versioning, and Presigned URLs on LocalStack

## 1. Technical Overview and Objective

The objective of Day 58 is to master object storage engineering using Amazon Simple Storage Service (S3) emulated on LocalStack. S3 is the foundational storage tier for modern cloud architectures, hosting static web assets, application logs, backups, and data lake pipelines. Mastering programmatic bucket operations, IAM bucket policies, object immutability via versioning, and secure time-limited presigned URL generation is essential for building scalable applications.

Key goals:
- Create and configure S3 buckets with declarative JSON bucket policies.
- Enable and verify object versioning to protect against accidental overwrites or deletions.
- Configure S3 Lifecycle configuration rules (transition to Glacier / expiration).
- Generate and test presigned URLs for secure, direct-to-S3 client file uploads.
- Automate multi-part file uploads and synchronization via the CLI.

---

## 2. Architecture and S3 Storage Breakdown

### 2.1 S3 Object Architecture and Access Flow

```
+-------------------------------------------------------------------------+
| AMAZON S3 BUCKET: roxs-voting-backups (Region: us-east-1)               |
+------------------------------------+------------------------------------+
| BUCKET POLICY (JSON IAM Syntax)    | LIFECYCLE MANAGEMENT               |
| - Deny unencrypted uploads         | - Prefix: "daily/"                 |
| - Enforce TLS 1.2+                 | - Expire after 30 days             |
+------------------------------------+------------------------------------+
                                     |
                                     v
| OBJECT REPOSITORY (Key-Value Hierarchy)                                 |
|                                                                         |
|  Key: backups/db-2026-10-06.sql                                         |
|  - Payload: Binary Data                                                 |
|  - Metadata: Content-Type, Content-MD5, x-amz-meta-environment          |
|  - Version History:                                                     |
|      + Version ID: v_98741 (Active)                                     |
|      + Version ID: v_54120 (Superseded)                                 |
+------------------------------------+------------------------------------+
                                     ^
                                     | Presigned URL (Valid for 15 mins)
+------------------------------------+------------------------------------+
| UNPRIVILEGED CLIENT BROWSER / SCRIPT (Uploads direct without AWS keys)   |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative S3 Bucket Policy (`bucket-policy.json`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceTLSRequestsOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::roxs-voting-backups",
        "arn:aws:s3:::roxs-voting-backups/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

### 3.2 S3 Lifecycle Configuration (`lifecycle.json`)

```json
{
  "Rules": [
    {
      "ID": "PruneOldBackups",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "backups/"
      },
      "Expiration": {
        "Days": 30
      },
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 7
      }
    }
  ]
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Create S3 bucket on LocalStack
aws --endpoint-url=http://localhost:4566 s3api create-bucket \
  --bucket roxs-voting-backups \
  --region us-east-1

# 2. Enable object versioning
aws --endpoint-url=http://localhost:4566 s3api put-bucket-versioning \
  --bucket roxs-voting-backups \
  --versioning-configuration Status=Enabled

# 3. Apply bucket security policy
aws --endpoint-url=http://localhost:4566 s3api put-bucket-policy \
  --bucket roxs-voting-backups \
  --policy file://bucket-policy.json

# 4. Apply lifecycle configuration
aws --endpoint-url=http://localhost:4566 s3api put-bucket-lifecycle-configuration \
  --bucket roxs-voting-backups \
  --lifecycle-configuration file://lifecycle.json

# 5. Upload sample application backup
echo "Postgres SQL Dump Mock Content" > backup.sql
aws --endpoint-url=http://localhost:4566 s3 cp backup.sql s3://roxs-voting-backups/backups/backup.sql
```

---

## 5. Real-World Verification Methods

```bash
# 1. Test versioning: Overwrite object and list all versions
echo "Updated SQL Dump Content v2" > backup.sql
aws --endpoint-url=http://localhost:4566 s3 cp backup.sql s3://roxs-voting-backups/backups/backup.sql
aws --endpoint-url=http://localhost:4566 s3api list-object-versions \
  --bucket roxs-voting-backups --prefix backups/backup.sql

# 2. Generate a presigned URL valid for 300 seconds
PRESIGNED_URL=$(aws --endpoint-url=http://localhost:4566 s3 presign s3://roxs-voting-backups/backups/backup.sql --expires-in 300)
echo "Generated Presigned URL: ${PRESIGNED_URL}"

# 3. Download object via presigned URL using standard curl without AWS credentials
curl -s "${PRESIGNED_URL}" | grep "Updated SQL Dump"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **S3 Path Style vs Virtual Hosted Style**:
   - Issue: SDK requests to `http://roxs-voting-backups.localhost:4566/` fail with DNS resolution errors.
   - Solution: Configure client SDKs to use **path-style** addressing (`s3_force_path_style = true` in Terraform or `s3ForcePathStyle: true` in JS SDK) so URLs resolve as `http://localhost:4566/roxs-voting-backups/`.

2. **Bucket Deletion with Versioning Enabled**:
   - Issue: `aws s3 rb s3://<bucket> --force` fails if versioning is active.
   - Cause: Standard deletion puts a Delete Marker on objects; historical versions remain intact.
   - Solution: To permanently destroy a versioned bucket, delete all version markers first using `s3api delete-objects` iterating through `list-object-versions`.

3. **Presigned URL Security Best Practices**:
   - Lesson: Presigned URLs inherit the exact IAM permissions of the identity that generated them at generation time. Keep expiration times minimal (5-15 minutes) to mitigate exposure if URLs leak.
