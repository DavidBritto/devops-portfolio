# Dia 53: PromQL Analytical Querying - Vector Types, Rate Calculations, and Histogram Quantiles

## 1. Technical Overview and Objective

The objective of Day 53 is to master Prometheus Query Language (PromQL). Collecting time-series metrics is useless without the ability to query, aggregate, and compute meaningful operational statistics from raw samples. PromQL is a functional query language designed specifically for evaluating nested operations over multi-dimensional time series.

Key goals:
- Understand the 4 core PromQL data types: **Instant Vector**, **Range Vector**, **Scalar**, and **String**.
- Master counter transformations: `rate()`, `irate()`, and `increase()`.
- Perform dimensional aggregations using `by` and `without` operators (`sum()`, `avg()`, `max()`).
- Calculate request latency percentiles using `histogram_quantile()`.
- Compute CPU, memory, and database saturation indicators.

---

## 2. Architecture and PromQL Vector Types Breakdown

### 2.1 Vector Types Conceptual Comparison

```
+-------------------------------------------------------------------------+
| INSTANT VECTOR: http_requests_total{status="200"}                      |
| Represents the single latest sample for each time series at timestamp T |
|                                                                         |
|  [vote-app-1] -> 1420                                                   |
|  [vote-app-2] -> 1380                                                   |
+-------------------------------------------------------------------------+

+-------------------------------------------------------------------------+
| RANGE VECTOR: http_requests_total{status="200"}[5m]                    |
| Represents a buffer of all samples collected over the past 5 minutes    |
| Required as input to functions like rate(), irate(), increase()         |
|                                                                         |
|  [vote-app-1] -> [1300@t-4m, 1330@t-3m, 1360@t-2m, 1390@t-1m, 1420@t]   |
+-------------------------------------------------------------------------+
```

---

## 3. Core PromQL Query Reference

### 3.1 Host & Infrastructure Queries (USE Method)

```promql
# 1. Total CPU Utilization Percentage across all cores
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 2. Host RAM Memory Utilization Percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 3. Disk Filesystem Saturation (Mount /)
(1 - (node_filesystem_free_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100
```

### 3.2 Microservice API Queries (RED Method)

```promql
# 1. Request Rate (Requests Per Second - RPS)
sum by (endpoint) (rate(http_requests_total[5m]))

# 2. HTTP Error Rate Percentage (5xx errors over total requests)
(sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) * 100

# 3. 99th Percentile Request Duration (p99 Latency in seconds)
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))
```

### 3.3 Database Metrics (PostgreSQL)

```promql
# Active database connections
sum(pg_stat_activity_count) by (datname)

# Transaction commit rate
rate(pg_stat_database_xact_commit{datname="votes"}[5m])
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Query instantaneous CPU idle rate via Prometheus HTTP API
curl -s -G http://localhost:9090/api/v1/query \
  --data-urlencode 'query=avg(rate(node_cpu_seconds_total{mode="idle"}[1m]))'

# 2. Query range vector over a 30-minute window
curl -s -G http://localhost:9090/api/v1/query_range \
  --data-urlencode 'query=up' \
  --data-urlencode 'start='$(date -d "30 minutes ago" +%s) \
  --data-urlencode 'end='$(date +%s) \
  --data-urlencode 'step=60'
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify PromQL syntax validity via API
curl -s -G http://localhost:9090/api/v1/query \
  --data-urlencode 'query=sum(rate(http_requests_total[5m]))' | grep '"status":"success"'

# 2. Test histogram bucket integrity
curl -s -G http://localhost:9090/api/v1/query \
  --data-urlencode 'query=http_request_duration_seconds_bucket' | head -n 20
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **`rate()` vs `irate()` Pitfalls**:
   - `rate()`: Calculates the per-second average rate over the entire range window (e.g. `[5m]`). Smooths out spikes and is ideal for alerting.
   - `irate()`: Calculates the instantaneous rate based solely on the last two data points within the window. Highly volatile; useful for diagnosing fast-moving transient spikes, but poor for alerting.

2. **The Counter Reset Trap**:
   - Behavior: When an application restarts, counters reset to zero.
   - Solution: `rate()` and `increase()` automatically detect counter resets (when a sample is lower than the previous one) and compensate, preventing negative rates. Never apply `deriv()` to counters.

3. **`histogram_quantile` Bucket Aggregation**:
   - Rule: When aggregating histogram buckets across instances using `sum()`, you MUST retain the `le` (less-than-or-equal) label: `sum by (le) (rate(..._bucket[5m]))`. Omitting `le` strips the bucket boundaries, causing `histogram_quantile` to fail or return NaN.
