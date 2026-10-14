# Dia 69: Chaos Engineering and Resilience - Fault Injection, Latency Simulation, and Graceful Degradation

## 1. Technical Overview and Objective

The objective of Day 69 is to proactively validate system resilience using Chaos Engineering principles. Complex distributed systems inevitably fail in unpredictable ways: network partitions occur, database connections time out, and nodes unexpectedly crash. Chaos Engineering is the discipline of experimenting on a software system to build confidence in its capability to withstand turbulent conditions in production.

Key goals:
- Understand the Principles of Chaos Engineering: Define steady state, hypothesize resilience, introduce realistic real-world events, and verify steady state.
- Simulate network latency and packet loss between microservices using Linux `tc` (Traffic Control) and netem.
- Inject sudden container crashes using Docker / Kubernetes pod termination drills.
- Validate that the frontend degrades gracefully (queues votes in Redis) when the PostgreSQL database experiences an outage.
- Measure Recovery Time Objective (RTO) and Mean Time to Recovery (MTTR) under chaotic failure injection.

---

## 2. Architecture and Chaos Experiment Flow Breakdown

### 2.1 Chaos Experiment Lifecycle

```
[1. DEFINE STEADY STATE]
  - Vote UI returns HTTP 200
  - k6 load test reports http_req_failed < 1%
  - Latency p95 < 200ms
           |
           v
[2. FORMULATE HYPOTHESIS]
  - "Killing the database container will degrade the Result UI,
     but the Vote frontend will continue accepting votes into Redis."
           |
           v
[3. INTRODUCE CHAOS VARIABLE]
  - Inject 500ms network latency to redis container
  - Terminate PostgreSQL database process abruptly
           |
           v
+-------------------------------------------------------------------------+
| [4. EVALUATE IMPACT & VERIFY HYPOTHESIS]                                |
|  - Does Vote UI continue operating without 500 errors?                 |
|  - Do Prometheus alerts fire within defined time windows?               |
|  - Does the Worker automatically reconnect once the DB recovers?        |
+------------------------------------+------------------------------------+
                                     |
                                     v
[5. HARDEN SYSTEM ARCHITECTURE]
  - Introduce circuit breakers, connection retries with exponential backoff
```

---

## 3. Configuration Breakdown

### 3.1 Fault Injection Script (`chaos-experiment.sh`)

```bash
#!/bin/bash
set -e

TARGET_CONTAINER=${1:-roxs-voting-app-redis-1}
DELAY_MS=${2:-500}

echo "Injecting ${DELAY_MS}ms artificial network latency into: ${TARGET_CONTAINER}..."

# Execute Traffic Control (tc) netem inside the target container's network namespace
docker exec --privileged "${TARGET_CONTAINER}" tc qdisc add dev eth0 root netem delay "${DELAY_MS}ms" 2>/dev/null || \
docker exec --privileged "${TARGET_CONTAINER}" tc qdisc change dev eth0 root netem delay "${DELAY_MS}ms"

echo "Latency injection active. Monitoring steady state..."
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Verify steady-state HTTP latency
curl -w "Time: %{time_total}s\n" -o /dev/null -s http://localhost:8080/

# 2. Inject artificial 300ms network delay into Redis
docker exec --privileged roxs-voting-app-redis-1 tc qdisc add dev eth0 root netem delay 300ms 2>/dev/null || true

# 3. Observe HTTP response latency increase
curl -w "Time: %{time_total}s\n" -o /dev/null -s http://localhost:8080/

# 4. Remove fault injection rule to restore steady state
docker exec --privileged roxs-voting-app-redis-1 tc qdisc del dev eth0 root 2>/dev/null || true
```

---

## 5. Real-World Verification Methods

```bash
# 1. Kill the database process while running load test
docker compose -f voting-app/roxs-voting-app/docker-compose.yml stop database

# 2. Check if vote frontend continues accepting votes (queued in Redis)
curl -s -X POST -d "vote=a" http://localhost:8080/
# Expected: Returns 200 / sets cookie (Graceful degradation)

# 3. Restart database container
docker compose -f voting-app/roxs-voting-app/docker-compose.yml start database

# 4. Confirm worker automatically reconnects and processes queued votes
docker compose -f voting-app/roxs-voting-app/docker-compose.yml logs worker --tail=20
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Exponential Backoff and Jitter**:
   - Issue: When a database recovers from a failure, 50 worker containers reconnect simultaneously at the exact same second (thundering herd problem), immediately crashing the database again.
   - Solution: Implement reconnection retries with exponential backoff and randomized jitter to distribute reconnection traffic smoothly.

2. **Blast Radius Containment**:
   - Rule: Always begin chaos experiments in development and staging environments before running them in production. Ensure an automated "kill switch" script exists to immediately revert all fault injection rules if unexpected cascading failures occur.

3. **Graceful Degradation Design**:
   - Lesson: Decoupling frontend ingestion from backend relational storage using an in-memory message queue (Redis) allows the Vote service to maintain 100% uptime for end users even during a complete backend database outage.
