# Dia 52: Infrastructure and Application Metrics Instrumentation - Node, Postgres, and Redis Exporters

## 1. Technical Overview and Objective

The objective of Day 52 is to implement metrics extraction across all layers of the technology stack using Prometheus Exporters and application client libraries. Systems like Linux kernels, PostgreSQL databases, and Redis caches do not expose Prometheus `/metrics` endpoints natively. Exporters act as translators: querying native OS system calls (`/proc`, `/sys`) or database statistics (`pg_stat_database`, `INFO stats`) and converting them into Prometheus exposition format.

Key goals:
- Deploy `node_exporter` to extract host Linux kernel metrics (CPU, RAM, disk I/O, network).
- Deploy `postgres_exporter` to monitor database connections, transaction commits, rollbacks, and table locks.
- Deploy `redis_exporter` to monitor memory usage, connected clients, cache hits/misses, and eviction rates.
- Instrument a Python/Flask application using `prometheus_client` to expose custom request counters and histograms.
- Validate metric outputs using curl.

---

## 2. Architecture and Exporter Integration Flow

### 2.1 Multi-Layer Exporter Architecture

```
+-------------------------------------------------------------------------+
| PROMETHEUS SCRAPING DAEMON                                              |
+-----+-----------------------+-----------------------+-------------------+
      | Port 9100             | Port 9187             | Port 9121         | Port 5000
      v                       v                       v                   v
+-----+----------+      +-----+----------+      +-----+----------+  +-----+----------+
| node_exporter  |      | postgres_      |      | redis_exporter |  | vote-app       |
|                |      |   exporter     |      |                |  | (Flask)        |
+-----+----------+      +-----+----------+      +-----+----------+  +-----+----------+
      | reads                 | queries SQL           | runs INFO         | internal
      v                       v                       v                   v
[Linux /proc &   ]      [PostgreSQL      ]      [Redis Server    ]  [Custom HTTP ]
[sys subsystems  ]      [pg_stat views   ]      [In-Memory Cache ]  [Middleware  ]
```

---

## 3. Configuration Breakdown

### 3.1 Docker Compose Exporter Stack (`docker-compose.monitoring-exporters.yml`)

```yaml
services:
  node-exporter:
    image: prom/node-exporter:v1.6.1
    container_name: node-exporter
    command:
      - '--path.rootfs=/host'
    pid: host
    restart: unless-stopped
    volumes:
      - '/:/host:ro,rslave'
    ports:
      - "9100:9100"

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:v0.13.2
    container_name: postgres-exporter
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres:postgres@database:5432/votes?sslmode=disable"
    ports:
      - "9187:9187"
    restart: unless-stopped

  redis-exporter:
    image: oliver006/redis_exporter:v1.52.0
    container_name: redis-exporter
    environment:
      REDIS_ADDR: "redis:6379"
    ports:
      - "9121:9121"
    restart: unless-stopped
```

### 3.2 Python Application Custom Instrumentation (`app_instrumented.py`)

```python
from flask import Flask, request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Define custom Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests processed',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency in seconds',
    ['endpoint'],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5]
)

@app.route('/vote', methods=['POST'])
def vote():
    with REQUEST_LATENCY.labels(endpoint='/vote').time():
        # Process vote logic...
        REQUEST_COUNT.labels(method='POST', endpoint='/vote', status='200').inc()
        return "Vote registered", 200

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Start exporters using Docker Compose
docker compose -f voting-app/roxs-voting-app/docker-compose.yml up -d postgres-exporter

# 2. Verify Node Exporter endpoint
curl -s http://localhost:9100/metrics | grep -E "^node_cpu_seconds_total" | head -n 5

# 3. Verify Postgres Exporter endpoint
curl -s http://localhost:9187/metrics | grep -E "^pg_stat_database_xact_commit" | head -n 5

# 4. Verify Redis Exporter endpoint
curl -s http://localhost:9121/metrics | grep -E "^redis_connected_clients" | head -n 5
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify metric data formats adhere strictly to Prometheus exposition standard
curl -s http://localhost:9100/metrics | grep -A 2 "node_memory_MemTotal_bytes"
# Expected format:
# # HELP node_memory_MemTotal_bytes Memory information field MemTotal_bytes.
# # TYPE node_memory_MemTotal_bytes gauge
# node_memory_MemTotal_bytes 1.6777216e+10

# 2. Confirm Prometheus targets dashboard shows exporters in state UP
curl -s http://localhost:9091/api/v1/targets | grep -o '"health":"up"' | wc -l
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **PostgreSQL Exporter Permission Denied**:
   - Issue: Exporter connects but returns zero table metrics.
   - Cause: Unprivileged database users cannot read from `pg_stat_database` or system catalogs.
   - Solution: Grant `pg_monitor` or `pg_read_all_stats` role to the exporter user: `GRANT pg_monitor TO postgres_exporter;`.

2. **Node Exporter Inside Docker Container**:
   - Issue: Node Exporter reports container memory limits instead of host machine memory.
   - Solution: Launch the container with `pid: host` and mount the root host filesystem into `/host:ro`, passing `--path.rootfs=/host` in the command arguments.

3. **Gauge vs Counter Metric Types**:
   - **Counter**: Cumulative metric that only increases or resets to zero upon restart (e.g., total requests, packets sent). Always wrap counters in `rate()` or `increase()`.
   - **Gauge**: Metric that represents a single numerical value that can go arbitrarily up or down (e.g., concurrent memory, CPU temperature, active connections).
