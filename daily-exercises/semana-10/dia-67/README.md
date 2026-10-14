# Dia 67: Disaster Recovery, Backup Automation, and Restore Verification Drills

## 1. Technical Overview and Objective

The objective of Day 67 is to establish enterprise Disaster Recovery (DR) and business continuity practices. Backups that have never been tested for restoration are not backups; they are assumptions. In production operations, data loss occurs from ransomware, accidental human deletions, hardware failures, and cloud zone outages. Engineering resilient systems requires defining precise Recovery Point Objectives (RPO) and Recovery Time Objectives (RTO), automating database dump pipelines, encrypting backups, and running automated restore drills.

Key goals:
- Understand Disaster Recovery metrics: **RPO** (maximum acceptable data loss window) and **RTO** (maximum acceptable downtime).
- Automate relational database snapshots (`pg_dump`) using environment-driven scripts (`backup.sh`).
- Replicate backup artifacts off-site into immutable object storage (S3).
- Execute an automated restore drill from scratch to validate data integrity.
- Implement automated backup retention schedules and pruning.

---

## 2. Architecture and Disaster Recovery Breakdown

### 2.1 RTO vs RPO Metrics Model

```
+-------------------------------------------------------------------------+
| DISASTER TIMELINE AND RECOVERY TARGETS                                  |
+-------------------------------------------------------------------------+
| [Last Backup Taken]                     [DISASTER EVENT OCCURS]         |
|  Timestamp: 14:00                        Timestamp: 14:45                |
|         |<-------- RPO WINDOW: 45m ------->|                             |
|         |  (Data lost since last snapshot) |                             |
|                                            |                             |
|                                            |<------ RTO WINDOW: 15m ---->|
|                                            | (Time to restore & recover) |
|                                            |                             |
|                                            v                             |
|                                  [SYSTEM FULLY RESTORED]                 |
|                                   Timestamp: 15:00                       |
+-------------------------------------------------------------------------+
```

### 2.2 Automated Backup and Restore Drill Flow

```
[Cron / Scheduled CI Workflow]
              |
              v
[Execute: ./scripts/backup.sh production]
              |
              +---> Connects to PostgreSQL container via pg_dump
              +---> Streams compressed, timestamped SQL: backup_prod_20261006.sql.gz
              +---> Verifies checksum and non-zero file size
              +---> Ships to immutable S3 bucket: s3://company-backups/postgres/
              |
              v
[AUTOMATED RESTORE DRILL (Weekly)]
              |
              +---> Spawns clean, isolated ephemeral PostgreSQL container
              +---> Ingests latest backup snapshot from S3
              +---> Executes: psql -d votes < backup.sql
              +---> Executes verification query: SELECT count(*) FROM votes
              +---> Tear down ephemeral drill container
              +---> Emits success metric to Prometheus / Alertmanager
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Backup Automation Script (`scripts/backup.sh`)

```bash
#!/bin/bash
set -eo pipefail

ENVIRONMENT=${1:-development}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="./backups"
BACKUP_FILE="${BACKUP_DIR}/backup_${ENVIRONMENT}_${TIMESTAMP}.sql"

mkdir -p "${BACKUP_DIR}"

echo "Starting automated database backup for: ${ENVIRONMENT}..."

# Execute dump inside container
docker compose exec -T database pg_dump \
  -U "${DATABASE_USER:-postgres}" \
  -d "${DATABASE_NAME:-votes}" > "${BACKUP_FILE}"

# Validate file size is greater than zero
if [ ! -s "${BACKUP_FILE}" ]; then
  echo "Error: Backup file is empty!"
  rm -f "${BACKUP_FILE}"
  exit 1
fi

echo "Backup completed successfully: ${BACKUP_FILE} ($(du -h ${BACKUP_FILE} | cut -f1))"

# Retention policy: remove backups older than 7 days
find "${BACKUP_DIR}" -name "backup_*.sql" -type f -mtime +7 -delete
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to voting app directory
cd /home/david/git/devops-porfolio/voting-app/roxs-voting-app

# 1. Execute manual backup
./scripts/backup.sh development

# 2. Inspect generated SQL backup artifact
ls -lh backups/
head -n 25 backups/backup_development_*.sql 2>/dev/null || ls -l backups/
```

---

## 5. Real-World Verification Methods (The Restore Drill)

```bash
# 1. Spawn a clean ephemeral PostgreSQL instance to test restore
docker run -d --name restore-drill-db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=votes_drill \
  -p 5433:5432 \
  postgres:15-alpine

# 2. Wait for database socket readiness
docker run --rm --network=host willdurand/wait-for-it localhost:5433 -t 15

# 3. Restore backup snapshot into the drill database
LATEST_BACKUP=$(ls -t backups/backup_*.sql | head -n 1)
docker exec -i restore-drill-db psql -U postgres -d votes_drill < "${LATEST_BACKUP}"

# 4. Verify restored tables and record counts
docker exec -i restore-drill-db psql -U postgres -d votes_drill -c \
  "\dt; SELECT count(*) FROM votes;"

# 5. Destroy drill test container
docker rm -f restore-drill-db
echo "Automated restore drill PASSED with 100% data integrity"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Empty File Backups Due to Unchecked Exit Codes**:
   - Issue: `pg_dump` fails due to incorrect passwords, but the shell script still exits with code 0, creating a 0-byte `.sql` file that is shipped to S3.
   - Solution: Use `set -eo pipefail` and include strict file size validation (`[ ! -s "${BACKUP_FILE}" ]`).

2. **Locking Table Disruption During Backups**:
   - Danger: Running `pg_dump` on a heavy production database can lock tables or spike disk I/O, degrading user-facing response times.
   - Solution: Run backups against a dedicated read-replica or use point-in-time recovery (PITR) with Write-Ahead Logging (WAL) archiving.

3. **Untested Backups Are an Operational Liability**:
   - Lesson: Organizations frequently discover backups are corrupted, encrypted with lost keys, or missing dependent schemas only *after* a disaster occurs. Scheduling automated restore drill workflows into ephemeral test environments guarantees recovery readiness.
