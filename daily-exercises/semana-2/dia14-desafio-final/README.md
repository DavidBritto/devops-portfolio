# Dia 14: Final Challenge Week 2 - Multi-Container Architecture with Docker Compose

## 1. Technical Overview and Objective

The objective of Day 14 is the consolidation of containerization principles into an enterprise-grade, multi-tier microservice architecture orchestrated via Docker Compose. Moving from isolated single-container workflows to declarative multi-container topologies requires mastering user-defined bridge networks, persistent named volumes, strict dependency sequencing via container healthchecks, and environment configuration management.

Key goals:
- Orchestrate 5 distributed services (Vote frontend, Worker processor, Result dashboard, Redis cache, and PostgreSQL database) using `docker-compose.yml`.
- Enforce service readiness ordering using `condition: service_healthy` instead of basic `depends_on`.
- Isolate inter-container communication using a dedicated user-defined bridge network (`votenet`).
- Persist state across container recreation cycles using named Docker volumes (`pgdata`).
- Externalize credentials and parameters using an uncommitted `.env` file with environment variable substitution.

---

## 2. Architecture and Workflow Breakdown

### 2.1 Multi-Container Topology

```
+-------------------------------------------------------------------------+
| HOST BROWSER / API CLIENT                                               |
|  - Vote Web UI:   http://localhost:8080 (Mapped to 5000 in container)   |
|  - Result Web UI: http://localhost:3000 (Mapped to 3000 in container)   |
+-------------------+---------------------------------+-------------------+
                    |                                 |
+-------------------v---------------------------------v-------------------+
| USER-DEFINED BRIDGE NETWORK: votenet (172.20.0.0/16)                   |
|                                                                         |
|  +------------------------+             +--------------------------+    |
|  | Container: vote        |             | Container: result        |    |
|  | Image: Python 3 Flask  |             | Image: Node.js Express   |    |
|  | Port: 5000             |             | Port: 3000               |    |
|  +-----------+------------+             +------------+-------------+    |
|              | (redis-py)                            | (pg driver)      |
|              v                                       v                  |
|  +------------------------+             +--------------------------+    |
|  | Container: redis       |             | Container: database      |    |
|  | Image: redis:7-alpine  |             | Image: postgres:15-alpine|    |
|  | Port: 6379             |             | Port: 5432               |    |
|  | Health: redis-cli ping |             | Health: pg_isready       |    |
|  +-----------+------------+             +------------+-------------+    |
|              ^                                       ^                  |
|              |               +-------------------+   |                  |
|              +---------------+ Container: worker |---+                  |
|                              | Image: Node.js    |                      |
|                              | Service Consumer  |                      |
|                              +-------------------+                      |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  | NAMED VOLUME: pgdata -> Mounted to /var/lib/postgresql/data       |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------------------------------------------------+
```

### 2.2 Healthcheck and Startup Dependency Flow

```
[docker compose up -d]
     |
     +---> [Spawn redis & database]
     |           |
     |           +---> redis runs: CMD redis-cli ping
     |           |     (Transitions to HEALTHY)
     |           |
     |           +---> database runs: pg_isready -U postgres
     |                 (Transitions to HEALTHY)
     |
     +---> [Condition Satisfied: redis healthy] --------> [Spawn vote]
     |
     +---> [Condition Satisfied: database healthy] -----> [Spawn result]
     |
     +---> [Condition Satisfied: redis & db healthy] ---> [Spawn worker]
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Compose Specification (`docker-compose.yml`)

```yaml
services:
  vote:
    build: ./vote
    ports:
      - "8080:5000"
    env_file:
      - .env
    networks:
      - votenet
    depends_on:
      redis:
        condition: service_healthy
    restart: on-failure

  result:
    build: ./result
    ports:
      - "3000:3000"
    env_file:
      - .env
    networks:
      - votenet
    depends_on:
      database:
        condition: service_healthy
    restart: on-failure

  worker:
    build: ./worker
    env_file:
      - .env
    networks:
      - votenet
    depends_on:
      database:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: on-failure

  redis:
    image: redis:7-alpine
    networks:
      - votenet
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  database:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${DATABASE_USER:-postgres}
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD:-postgres}
      POSTGRES_DB: ${DATABASE_NAME:-votes}
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - votenet
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DATABASE_USER:-postgres} -d ${DATABASE_NAME:-votes}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

networks:
  votenet:
    driver: bridge

volumes:
  pgdata:
    driver: local
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to voting app directory
cd /home/david/git/devops-porfolio/voting-app/roxs-voting-app

# Create environment configuration file if missing
cat <<EOF > .env
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=votes
DATABASE_HOST=database
REDIS_HOST=redis
PORT=3000
EOF

# Build container images and start all services in detached mode
docker compose up -d --build

# Verify container runtime statuses and healthcheck indicators
docker compose ps

# Follow unified real-time logs across the stack
docker compose logs -f --tail=20
```

---

## 5. Real-World Verification Methods

```bash
# 1. Inspect active network and verify service DNS resolution
docker network inspect roxs-voting-app_votenet

# 2. Test Vote frontend health
curl -sI http://localhost:8080 | head -n 5

# 3. Test Result frontend health
curl -sI http://localhost:3000 | head -n 5

# 4. Cast a vote via HTTP POST
curl -s -X POST -d "vote=b" http://localhost:8080/

# 5. Query PostgreSQL container directly to verify worker written data
docker compose exec database psql -U postgres -d votes -c "SELECT vote, count(vote) FROM votes GROUP BY vote;"

# 6. Test Data Persistence across container recreation
docker compose down
docker compose up -d
docker compose exec database psql -U postgres -d votes -c "SELECT vote, count(vote) FROM votes GROUP BY vote;"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Race Conditions During Cold Boots**:
   - Issue: The `worker` container crashed on startup because PostgreSQL was initializing its cluster files and rejecting socket connections.
   - Root Cause: Standard `depends_on: [database]` only waits until the container is created, not until the database engine is accepting client connections.
   - Solution: Implement `healthcheck` with `pg_isready` and configure `condition: service_healthy` on dependent services.

2. **Database Authentication Failure in Compose**:
   - Issue: Changing `.env` credentials after initial boot causes PostgreSQL connection authentication errors.
   - Root Cause: PostgreSQL initializes superuser credentials only on the first run when the data directory (`/var/lib/postgresql/data`) is empty. Recreating containers mounts the existing volume with the old password.
   - Solution: Either keep password consistent or purge the named volume during local development: `docker compose down -v`.

3. **Bridge Network Name Resolution**:
   - Issue: Containers on the default bridge network (`bridge`) cannot resolve each other by container name.
   - Solution: Always create a user-defined custom bridge network (`networks: [votenet]`), which provides automatic internal DNS resolution managed by the Docker Engine daemon.
