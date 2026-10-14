# Dia 55: Prometheus Alertmanager - Alert Evaluation, Routing Trees, and Incident Notification

## 1. Technical Overview and Objective

The objective of Day 55 is to master automated alert evaluation and incident notification pipelines using Prometheus Alertmanager. Metric collection without alerting requires continuous human monitoring of dashboards, which is unsustainable. Conversely, naive alerting leads to "alert fatigue" -- flooding on-call engineers with duplicate or non-actionable notifications. Prometheus evaluates alerting rules written in PromQL, transitioning alerts through lifecycle states (`Inactive` -> `Pending` -> `Firing`), while Alertmanager handles deduplication, grouping, inhibition, silencing, and multi-channel routing.

Key goals:
- Author declarative Prometheus alerting rules (`alert.rules.yml`).
- Understand alert lifecycle phases: Inactive, Pending (grace period), and Firing.
- Configure Alertmanager routing trees based on label matchers (`severity`, `team`).
- Implement alert **Grouping** (`group_by`, `group_wait`, `group_interval`) to collapse storm notifications.
- Configure alert **Inhibition** rules to suppress downstream alerts during root-cause outages.

---

## 2. Architecture and Alert Lifecycle Breakdown

### 2.1 Prometheus to Alertmanager Notification Flow

```
[Prometheus Server (Port 9090)]
       |
       | Evaluates PromQL rule every 'evaluation_interval: 15s'
       v
+-------------------------------------------------------------------------+
| ALERT LIFECYCLE EVALUATION                                              |
|                                                                         |
|  [State: INACTIVE]                                                      |
|         | Condition becomes TRUE (e.g. CPU > 90%)                       |
|         v                                                               |
|  [State: PENDING]                                                       |
|         | Condition remains TRUE for duration of 'for: 2m'              |
|         v (Prevents transient spikes from waking engineers)             |
|  [State: FIRING]                                                        |
+------------------------------------+------------------------------------+
                                     | HTTP POST to Alertmanager (Port 9093)
                                     v
+-------------------------------------------------------------------------+
| ALERTMANAGER ENGINE                                                     |
|                                                                         |
|  1. Deduplication & Grouping: Combines 50 pod crashes into 1 message    |
|  2. Inhibition: Host is DOWN? -> Mute all 'ProcessDown' child alerts    |
|  3. Silencing: Maintenance window active? -> Suppress alert             |
|  4. Routing Tree: Evaluates labels (severity: critical -> PagerDuty)    |
+------------------------------------+------------------------------------+
                                     | Dispatches Notification
                                     v
                 [Slack / Discord / PagerDuty / Email Webhook]
```

---

## 3. Configuration Breakdown

### 3.1 Prometheus Alerting Rules (`alert.rules.yml`)

```yaml
groups:
  - name: voting_app_alerts
    rules:
      # Critical: Service completely unreachable
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
          team: devops
        annotations:
          summary: "Service {{ $labels.instance }} is down"
          description: "Target has been unreachable for more than 1 minute."

      # Warning: High HTTP 5xx error rate
      - alert: HighHttpErrorRate
        expr: (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100 > 5
        for: 2m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: "High HTTP 5xx rate detected"
          description: "Error rate is {{ $value }}% on service {{ $labels.service }}."
```

### 3.2 Alertmanager Configuration (`alertmanager.yml`)

```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default-webhook'

  routes:
    # Route critical alerts to on-call pager
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
      continue: true

    # Route backend team warnings to Slack
    - match:
        team: backend
      receiver: 'slack-backend'

receivers:
  - name: 'default-webhook'
    webhook_configs:
      - url: 'http://notification-service:8080/alerts'
        send_resolved: true

  - name: 'pagerduty-critical'
    webhook_configs:
      - url: 'http://mock-pagerduty:8080/incident'

  - name: 'slack-backend'
    slack_configs:
      - channel: '#devops-alerts'
        api_url: 'https://hooks.slack.com/services/MOCK/TOKEN/HERE'

inhibit_rules:
  # If a Node is down, mute individual application down alerts on that same node
  - source_match:
      alertname: 'NodeNetworkDown'
    target_match:
      alertname: 'ServiceDown'
    equal: ['node']
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Validate Prometheus rule syntax using promtool
docker run --rm -v $(pwd):/work -w /work prom/prometheus:v2.45.0 \
  promtool check rules alert.rules.yml

# 2. Validate Alertmanager configuration syntax using amtool
docker run --rm -v $(pwd):/work -w /work prom/alertmanager:v0.25.0 \
  amtool check-config alertmanager.yml

# 3. Query active alert states in Prometheus API
curl -s http://localhost:9090/api/v1/alerts | grep -o '"state":"[^"]*"'
```

---

## 5. Real-World Verification Methods

```bash
# 1. Simulate an alert by stopping an exporter container
docker stop postgres-exporter 2>/dev/null || true

# 2. Wait 1 minute and query Prometheus alerts endpoint
# State transitions from 'pending' to 'firing'
curl -s http://localhost:9090/api/v1/alerts | grep -E "ServiceDown|firing"

# 3. Create a temporary Silence via Alertmanager CLI (amtool)
# amtool silence add alertname=ServiceDown --duration=1h --comment="Planned maintenance"

# 4. Restart container to verify automatic alert resolution (send_resolved: true)
docker start postgres-exporter 2>/dev/null || true
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **The `for:` Clause Importance**:
   - Issue: Alerting triggers immediately on transient 1-second network hiccups or garbage collection pauses.
   - Solution: Always define `for: 1m` or `for: 5m` in alerting rules. The condition must evaluate to true continuously throughout this duration before transitioning to `Firing`.

2. **Alert Storms and `group_wait`**:
   - Issue: When a network switch fails, 50 nodes become unreachable simultaneously, sending 50 separate SMS notifications to the on-call engineer within 2 seconds.
   - Solution: Configure `group_by: ['alertname', 'cluster']` and `group_wait: 30s`. Alertmanager buffers initial alerts for 30 seconds, batching all 50 occurrences into a single consolidated notification.

3. **Resolved Notifications (`send_resolved: true`)**:
   - Practice: Always enable `send_resolved: true` on notification receivers. Letting engineers know when an incident has recovered automatically prevents unnecessary manual interventions.
