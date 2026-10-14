# Dia 65: Advanced Performance Testing - Stress, Spike, and Soak Testing Methodologies

## 1. Technical Overview and Objective

The objective of Day 65 is to evaluate system limits and endurance using advanced performance testing profiles. While standard load testing validates that a system meets baseline Service Level Agreements (SLAs) under expected traffic, it does not reveal what happens during unexpected marketing surges, denial of service attempts, or prolonged execution. Implementing Stress, Spike, and Soak testing allows engineers to discover exact breaking points, test graceful degradation, and detect gradual memory leaks or connection pool starvation.

Key goals:
- Compare testing profiles: **Load** (expected traffic), **Stress** (breaking point discovery), **Spike** (sudden catastrophic surge), and **Soak** (prolonged endurance).
- Configure a multi-stage k6 stress script pushing the application beyond capacity.
- Monitor container resource consumption, garbage collection, and database connection limits during stress phases.
- Identify memory leaks and file descriptor exhaustion via long-running soak tests.
- Verify system self-recovery once load returns to nominal levels.

---

## 2. Architecture and Testing Profiles Breakdown

### 2.1 Load Testing Profiles Comparison

```
+-------------------------------------------------------------------------+
| TESTING LOAD PROFILES VISUALIZATION                                     |
+-------------------------------------------------------------------------+
| 1. STRESS TEST (Gradual step increase until degradation / crash)        |
|    VUs: 50 -> 100 -> 250 -> 500 -> 1000                                 |
|    Goal: Identify maximum sustainable throughput and breaking point.     |
+-------------------------------------------------------------------------+
| 2. SPIKE TEST (Instant jump from baseline to extreme load)              |
|    VUs: 10 -> 800 (within 10s) -> 10                                    |
|    Goal: Verify autoscaling reaction, circuit breaking, zero crashes.   |
+-------------------------------------------------------------------------+
| 3. SOAK TEST (Moderate load held continuously for 4-24 hours)           |
|    VUs: 50 held constant for 12 hours                                  |
|    Goal: Identify memory leaks, disk buffer filling, DB pool leakage.   |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Stress and Spike k6 Specification (`stress-spike.js`)

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },   // Baseline warm-up
    { duration: '2m', target: 200 },  // Heavy stress
    { duration: '10s', target: 600 }, // Catastrophic spike
    { duration: '1m', target: 600 },  // Sustained peak load
    { duration: '30s', target: 50 },  // Rapid scale down to test recovery
    { duration: '1m', target: 0 },    // Cooldown
  ],
  thresholds: {
    // Under extreme stress, allow higher latency but enforce error bounds
    http_req_duration: ['p(90)<500'],
    http_req_failed: ['rate<0.05'], // Keep failures below 5%
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://localhost:8080';

export default function () {
  const res = http.get(`${BASE_URL}/`);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(0.5);
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Execute stress test using k6 container
docker run --rm -i --network=host \
  -e TARGET_URL="http://localhost:8080" \
  grafana/k6:latest run - < stress-spike.js

# 2. Concurrently monitor container CPU and memory usage
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
```

---

## 5. Real-World Verification Methods

```bash
# 1. Check for memory leak indications during soak test
# Memory should plateau and stabilize; continuous linear growth indicates a leak
docker stats --no-stream --format "{{.Name}}: {{.MemUsage}}"

# 2. Check open file descriptors on the host
cat /proc/sys/fs/file-nr

# 3. Check PostgreSQL connection pool saturation
docker exec -i roxs-voting-app-database-1 psql -U postgres -d votes -c \
  "SELECT count(*) as active_connections FROM pg_stat_activity;"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Database Connection Pool Exhaustion**:
   - Symptoms: Under high stress, response times jump from 15ms to 10,000ms, and applications throw `FATAL: remaining connection slots are reserved for non-replication superuser connections`.
   - Root Cause: Each web worker opens new connections rather than using a pooled client (e.g. PgBouncer or native connection pooling).
   - Solution: Configure bounded connection pools (e.g. max 20 connections per container instance) and implement connection queuing.

2. **Memory Leaks Identified via Soak Testing**:
   - Lesson: A 5-minute load test will never catch a 20KB memory leak per request. In a 12-hour soak test running at 100 RPS, that 20KB leak accumulates to over 80GB of RAM, triggering kernel OOM kills. Always conduct soak tests prior to major production releases.

3. **Graceful Degradation over Hard Failure**:
   - Architecture Best Practice: When traffic exceeds max capacity, systems should return HTTP 429 Too Many Requests or serve cached read-only content, rather than crashing backend database engines.
