# Dia 51: Prometheus Core Architecture - Pull Model, TSDB Internals, and Scrape Configurations

## 1. Technical Overview and Objective

The objective of Day 51 is to master the architecture of Prometheus, the Cloud Native Computing Foundation (CNCF) standard for systems monitoring and time-series data storage. Unlike traditional push-based monitoring systems that require target nodes to push metrics to a central server, Prometheus employs an active pull-based model, scraping standard HTTP `/metrics` endpoints at configurable intervals. This decoupled architecture simplifies agent health detection, supports automatic service discovery, and avoids central database ingestion bottlenecks.

Key goals:
- Understand the Prometheus pull model vs push model trade-offs.
- Analyze the Time Series Database (TSDB) internals: Head chunk memory, Write-Ahead Log (WAL), block compaction, and retention.
- Configure `prometheus.yml`: global intervals, scrape configurations, and metric relabeling.
- Implement static targets and explore Kubernetes/Docker Service Discovery (SD).
- Run and verify a standalone Prometheus container instance.

---

## 2. Architecture and Prometheus TSDB Breakdown

### 2.1 Prometheus System Architecture

```
+-------------------------------------------------------------------------+
| PROMETHEUS SERVER                                                       |
|                                                                         |
|  [Retrieval / Scrape Engine]                                            |
|   - Pulls metrics every 15s via HTTP GET                                |
|   - Service Discovery (Kubernetes API, Docker Engine, DNS)              |
|         |                                                               |
|         v                                                               |
|  [TSDB (Time Series Database)]                                          |
|   - Head block in memory (Recent 2 hours)                               |
|   - Write-Ahead Log (WAL) for crash recovery                            |
|   - Immutable 2-hour blocks compacted to disk                           |
|         |                                                               |
|         v PromQL Engine                                                 |
|  [HTTP API: Port 9090] <------------- Queries from Grafana / Web UI     |
|         |                                                               |
|         v Alert Evaluation                                              |
|  [Pushes alerts] -------------------> [Alertmanager: Port 9093]         |
+-------------------------------------------------------------------------+
                     | Pull (HTTP /metrics)
       +-------------+-------------+
       v                           v
[Target 1: Node Exporter]   [Target 2: App Service /metrics]
```

### 2.2 TSDB Storage Layout on Disk

```
/data/prometheus/
├── 01BKGV7JC00MD656Q4Y6V3DVT9/   # 2-hour compacted data block
│   ├── meta.json                  # Block time range and series statistics
│   ├── chunks/000001             # Compressed raw samples (Gorilla compression)
│   └── index                      # Inverted index (label names and values to IDs)
├── wal/                           # Write-Ahead Log directory
│   ├── 00000001
│   └── 00000002
└── lock
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Prometheus Configuration (`prometheus.yml`)

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s

scrape_configs:
  # Self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Host infrastructure metrics
  - job_name: 'node-exporter'
    scrape_interval: 10s
    static_configs:
      - targets: ['node-exporter:9100']

  # Application microservices metrics
  - job_name: 'voting-app-vote'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['vote:5000']
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Create a dedicated workspace directory
mkdir -p /tmp/prometheus-lab && cd /tmp/prometheus-lab

# 2. Write the configuration file
cat <<EOF > prometheus.yml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# 3. Launch Prometheus container with persistent volume
docker run -d \
  --name prometheus-core \
  -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:v2.45.0

# 4. Verify container is healthy
docker ps -f name=prometheus-core
```

---

## 5. Real-World Verification Methods

```bash
# 1. Query Prometheus targets health API
curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"[^"]*"'

# 2. Query Prometheus runtime build info via PromQL API
curl -s -G http://localhost:9090/api/v1/query --data-urlencode 'query=prometheus_build_info'

# 3. Clean up container
docker rm -f prometheus-core
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Slow Scrapes and `context deadline exceeded`**:
   - Issue: Target shows `DOWN` in Prometheus UI with error `context deadline exceeded`.
   - Cause: The target takes longer than `scrape_timeout` (default 10s) to generate the `/metrics` payload.
   - Solution: Profile the application's metrics serializer. Scrapes must complete in milliseconds. Never run heavy database queries synchronously inside `/metrics` request handlers.

2. **Disk Growth and Retention Tuning**:
   - Issue: Prometheus fills host disk space over several weeks.
   - Solution: Configure `--storage.tsdb.retention.time=15d` and `--storage.tsdb.retention.size=50GB` flags in the Prometheus daemon startup arguments.

3. **In-Flight Sample Recovery via WAL**:
   - Lesson: The Write-Ahead Log (WAL) records every newly ingested metric sample to disk sequentially before committing it into memory. If the host experiences an abrupt power outage, Prometheus replays the WAL on restart with zero data corruption.
