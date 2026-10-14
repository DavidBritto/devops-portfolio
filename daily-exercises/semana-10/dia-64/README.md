# Dia 64: Performance Engineering and Load Testing with Grafana k6

## 1. Technical Overview and Objective

The objective of Day 64 is to establish automated performance engineering using Grafana k6. Applications that function correctly in isolated unit tests frequently collapse under production traffic due to database lock contention, socket exhaustion, or inefficient memory allocation. k6 is a developer-centric, scriptable load testing tool written in Go with a JavaScript ES6 execution runtime, capable of simulating thousands of concurrent Virtual Users (VUs) with minimal CPU and memory footprints.

Key goals:
- Understand k6 architecture: Go runtime, JavaScript ES6 engine, and Virtual Users (VUs).
- Structure k6 test lifecycles: `init`, `setup`, `default` (VU iteration loop), and `teardown`.
- Implement functional assertions (`check()`) and non-functional performance gates (`thresholds`).
- Simulate concurrent voting traffic against the Vote frontend API.
- Execute automated load tests with pass/fail exit codes suitable for CI/CD pipelines.

---

## 2. Architecture and k6 Test Execution Lifecycle

### 2.1 k6 Test Execution Flow

```
[k6 Engine Initialization (Go Runtime)]
                 |
                 +---> 1. INIT CODE: Imports modules, reads local JSON fixtures
                 |
                 +---> 2. SETUP CODE (Run once): Seeds test database, verifies target health
                 |
                 v
+-------------------------------------------------------------------------+
| VU EXECUTION PHASE (Default Code - Parallel VUs)                        |
|                                                                         |
|  [Virtual User 1]  ---> HTTP POST /vote (Option A)  ---> check(status=200)|
|  [Virtual User 2]  ---> HTTP POST /vote (Option B)  ---> check(status=200)|
|  [Virtual User N]  ---> HTTP GET  /health           ---> check(status=200)|
|                                                                         |
|  - Metrics Collected: http_req_duration, http_req_failed, vus, iterations|
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
| EVALUATION PHASE                                                        |
|  - TEARDOWN CODE (Run once): Clean up temporary test data               |
|  - THRESHOLDS CHECK:                                                    |
|      + http_req_duration (p95 < 200ms)?                                 |
|      + http_req_failed (rate < 1%)?                                     |
|      |                                                                  |
|      +---> All Passed  ---> EXIT CODE 0 (CI Build Success)              |
|      +---> Any Breached ---> EXIT CODE 99 (CI Build Fail)               |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Load Test Script (`load-test.js`)

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

// 1. Test Options & Performance SLO Thresholds
export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp-up to 20 VUs
    { duration: '1m',  target: 50 },  // Steady state at 50 VUs
    { duration: '20s', target: 0 },   // Ramp-down to 0 VUs
  ],
  thresholds: {
    // 95% of requests must complete below 200ms
    http_req_duration: ['p(95)<200'],
    // Less than 1% of requests may fail
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://localhost:8080';

// 2. Virtual User Execution Loop
export default function () {
  const optionsList = ['a', 'b'];
  const randomVote = optionsList[Math.floor(Math.random() * optionsList.length)];

  const payload = `vote=${randomVote}`;
  const params = {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  };

  // Submit Vote
  const res = http.post(`${BASE_URL}/`, payload, params);

  // Validate response status
  check(res, {
    'status is 200 or 302': (r) => r.status === 200 || r.status === 302,
  });

  // User think time between actions (1 second)
  sleep(1);
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Run k6 load test via Docker container targeting the Vote service
docker run --rm -i --network=host \
  -e TARGET_URL="http://localhost:8080" \
  grafana/k6:latest run - < voting-app/roxs-voting-app/load-testing/k6.js

# 2. Run k6 with real-time output and custom VU override
docker run --rm -i --network=host \
  grafana/k6:latest run --vus 10 --duration 30s - < load-test.js
```

---

## 5. Real-World Verification Methods

```bash
# 1. Inspect k6 summary report output
# Look for:
# - http_req_duration..............: avg=12.4ms min=1.2ms med=8.1ms max=145ms p(90)=24ms p(95)=38ms
# - http_req_failed................: 0.00%
# - checks.........................: 100.00%

# 2. Check exit code: returns 0 on threshold pass, non-zero on breach
echo "k6 Exit Code: $?"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Host Ephemeral Port Exhaustion**:
   - Issue: Load testing fails abruptly with `dial tcp: bind: address already in use` under high VU counts.
   - Cause: Linux runs out of local ephemeral ports (`net.ipv4.ip_local_port_range`).
   - Solution: Enable socket reuse in the host kernel: `sudo sysctl -w net.ipv4.tcp_tw_reuse=1`.

2. **Thresholds as CI Quality Gates**:
   - Practice: Define `thresholds` for every critical service path. If an application change introduces an N+1 database query, the `p(95)<200ms` threshold trips in CI before bad code reaches production.

3. **Virtual User Sleep Intervals**:
   - Anti-Pattern: Omitting `sleep()` in VU loops generates unrealistic "DDoS" traffic where each VU hammers the server with zero think time, masking normal operational characteristics.
