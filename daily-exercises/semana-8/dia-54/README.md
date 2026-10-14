# Dia 54: Grafana Dashboards as Code - Provisioning, Dynamic Templating, and Visualizations

## 1. Technical Overview and Objective

The objective of Day 54 is to establish declarative observability dashboards using Grafana. In enterprise environments, creating dashboards manually via the point-and-click graphical user interface creates operational drift, risks accidental deletion, and prevents dashboards from being reviewed or version-controlled in Git. Implementing "Dashboards as Code" allows engineering teams to provision data sources and dashboard JSON definitions automatically upon container boot.

Key goals:
- Configure Grafana Datasource provisioning via YAML.
- Configure Grafana Dashboard provisioning via YAML provider manifests and JSON schemas.
- Implement multi-tenant dynamic dashboard variables (`$instance`, `$environment`, `$service`).
- Structure effective visualizations: Stat panels for single values, Time-Series for rates, and Heatmaps for latency histograms.
- Validate automatic dashboard loading on container startup.

---

## 2. Architecture and Provisioning Flow Breakdown

### 2.1 Grafana Automated Provisioning Flow

```
[Repository: voting-app/roxs-voting-app/monitoring/grafana]
├── provisioning/
│   ├── datasources/
│   │   └── prometheus-ds.yml   # Points to http://prometheus:9090
│   └── dashboards/
│       └── dashboard-provider.yml # Scans /var/lib/grafana/dashboards
└── dashboards/
    └── voting-app-overview.json # Complete dashboard specification
          |
          v Mounted as Docker Volumes
+-------------------------------------------------------------------------+
| GRAFANA SERVER CONTAINER (Port 3000)                                    |
|                                                                         |
|  1. Boot sequence evaluates /etc/grafana/provisioning/datasources       |
|  2. Registers Prometheus datasource without manual UI clicks            |
|  3. Evaluates /etc/grafana/provisioning/dashboards                      |
|  4. Ingests JSON files into sqlite3 cache                               |
|  5. Exposes rendered dashboards instantly to users                      |
+-------------------------------------------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Datasource Provisioning Manifest (`datasources/prometheus.yml`)

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
    jsonData:
      timeInterval: 15s
      httpMethod: POST
```

### 3.2 Dashboard Provider Manifest (`dashboards/provider.yml`)

```yaml
apiVersion: 1

providers:
  - name: 'DevOps Portfolio Dashboards'
    orgId: 1
    folder: 'Microservices'
    type: file
    disableDeletion: true
    editable: true
    options:
      path: /etc/grafana/dashboards
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Inspect existing Grafana provisioning manifests in the portfolio
cat voting-app/roxs-voting-app/monitoring/grafana/provisioning/prometheus.yml 2>/dev/null || true

# 2. Start Grafana with mounted provisioning directories
docker run -d \
  --name grafana-lab \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -v $(pwd)/voting-app/roxs-voting-app/monitoring/grafana/provisioning:/etc/grafana/provisioning \
  grafana/grafana-oss:10.0.0

# 3. Verify Grafana runtime logs
docker logs grafana-lab --tail=20
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify datasource registration via Grafana REST API
curl -s -u admin:admin http://localhost:3000/api/datasources | grep -o '"name":"Prometheus"'

# 2. Query dashboards API to confirm JSON ingestion
curl -s -u admin:admin http://localhost:3000/api/search?type=dash-db

# 3. Clean up container
docker rm -f grafana-lab
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Datasource URL Resolution Inside Docker Bridges**:
   - Issue: Grafana datasource configured as `http://localhost:9090` fails with `HTTP Error Bad Gateway`.
   - Cause: `localhost` inside the Grafana container refers to the Grafana container itself, not the host machine or Prometheus container.
   - Solution: Use the Docker Compose service name (`http://prometheus:9090`) or host gateway (`http://host.docker.internal:9090`).

2. **`editable: false` in Production Dashboards**:
   - Practice: Setting `editable: false` in datasource and dashboard providers prevents on-call engineers from accidentally modifying production dashboards during high-stress incident responses.

3. **Dashboard JSON Schema Management**:
   - Lesson: Manually editing 2,000-line Grafana JSON files is error-prone. Modern teams either export JSON from an ephemeral instance and commit to Git, or generate dashboards programmatically using tools like Grafonnet (Jsonnet) or Terraform (`grafana_dashboard` resource).
