# Dia 56: Final Challenge Week 8 - Full Observability Stack with Automated Alerting on Roxs Voting App

## 1. Technical Overview and Objective

The objective of Day 56 is the complete deployment and verification of an enterprise observability stack integrated into the Roxs Voting App. This capstone challenge for Week 8 unifies multi-layer metric collection (infrastructure, database, cache, and HTTP application metrics) using Prometheus, automated incident triage using Alertmanager, and real-time operational visualization using Grafana dashboards provisioned entirely as code.

Key goals:
- Deploy Prometheus, Grafana, Alertmanager, Postgres-Exporter, and Redis-Exporter alongside the Roxs Voting App stack.
- Configure automated scraping across all 5 tiers of the microservices topology.
- Provision Grafana datasources and pre-configured executive dashboards automatically upon boot.
- Deploy alerting rules tracking Service Availability, Database Saturation, and Queue Congestion.
- Simulate an intentional outage and verify automated alert firing and resolution.

---

## 2. Architecture and Complete Observability Topology

### 2.1 Complete Monitoring Architecture

```
+-------------------------------------------------------------------------+
| APPLICATION LAYER (Roxs Voting App)                                     |
|                                                                         |
|  [vote (Python:5000)]     [worker (Node.js)]     [result (Node.js:3000)]|
|  [redis:6379]             [database:5432]                               |
+-------+--------------------------+-----------------------+--------------+
        |                          |                       |
        v                          v                       v
+-------+--------------------------+-----------------------+--------------+
| EXPORTER LAYER                                                          |
|  - redis-exporter (Port 9121)     - postgres-exporter (Port 9187)        |
|  - vote /metrics (Port 5000)      - node-exporter (Port 9100)           |
+-------+--------------------------+-----------------------+--------------+
        | Scrape Targets (HTTP GET every 15s)
        v
+-------------------------------------------------------------------------+
| PROMETHEUS SERVER (Port 9091)                                           |
|  - TSDB Engine, Inverted Index                                          |
|  - Rule Evaluation Engine (alert.rules.yml)                             |
+-------+--------------------------------------------------+--------------+
        | Alerts (Port 9093)                               | PromQL (HTTP)
        v                                                  v
+-----------------------+                  +------------------------------+
| ALERTMANAGER          |                  | GRAFANA DASHBOARDS (Port 3003|
| - Grouping & Routing  |                  | - Voting App Overview        |
| - Receiver Webhooks   |                  | - Database Performance       |
+-----------------------+                  +------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Integrated Docker Compose Manifest (`docker-compose.observability.yml`)

```yaml
services:
  prometheus:
    image: prom/prometheus:v2.45.0
    container_name: prometheus
    ports:
      - "9091:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./monitoring/alert.rules.yml:/etc/prometheus/alert.rules.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    networks:
      - votenet

  grafana:
    image: grafana/grafana-oss:10.0.0
    container_name: grafana
    ports:
      - "3003:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
    networks:
      - votenet
    depends_on:
      - prometheus

  alertmanager:
    image: prom/alertmanager:v0.25.0
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./monitoring/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    networks:
      - votenet
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to the voting app project directory
cd /home/david/git/devops-porfolio/voting-app/roxs-voting-app

# 1. Start the entire application and monitoring stack
docker compose up -d

# 2. Verify all containers are operational
docker compose ps

# 3. Check Prometheus targets status
curl -s http://localhost:9091/api/v1/targets | grep -o '"health":"up"'
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify Grafana UI is accessible and datasource is loaded
curl -s -u admin:admin http://localhost:3003/api/datasources | grep "Prometheus"

# 2. Simulate Outage: Stop the database container
docker compose stop database

# 3. Verify Prometheus evaluates PostgresDown alert
curl -s http://localhost:9091/api/v1/alerts

# 4. Recover the database container
docker compose start database

# 5. Confirm alert resolves automatically in Prometheus
curl -s http://localhost:9091/api/v1/alerts | grep -i "inactive" || true
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Port Mapping Decoupling**:
   - In `docker-compose.yml`, Prometheus is exposed on host port `9091` to avoid conflicting with existing system services on `9090`, and Grafana on `3003` to avoid collision with the Result UI on `3000`.

2. **Metrics Collection Cost**:
   - Lesson: Scraping at extremely high frequencies (`1s`) increases network overhead and TSDB write operations without adding diagnostic value for macro-trends. 10s-15s intervals represent the production sweet spot for microservices.

3. **Dashboard Provisioning Idempotency**:
   - Practice: Always assign deterministic `uid` strings in provisioned Grafana dashboard JSON files (e.g. `"uid": "voting-app-overview"`). Omitting the UID causes Grafana to regenerate IDs on restarts, breaking external browser bookmarks and alert links.
