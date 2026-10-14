# Semana 8: Observability, Prometheus, Grafana, PromQL, and Alertmanager

## Overview

Week 8 establishes full operational visibility into containerized and distributed infrastructure through modern Observability engineering. You cannot improve or reliably maintain what you cannot measure. Moving beyond basic health checks, this week covers the three pillars of observability (Metrics, Logs, and Traces), time-series database architecture with Prometheus, custom metrics instrumentation, systems exporters, PromQL analytical querying, Grafana dashboard visualization, and automated alert notification routing via Alertmanager.

---

## Technical Curriculum Breakdown

| Day | Topic | Key Concepts and Deliverables |
|---|---|---|
| Dia 50 | Observability Fundamentals | Metrics, Logs, Traces; Blackbox vs Whitebox monitoring; RED/USE methods |
| Dia 51 | Prometheus Core Architecture | Pull-based scraping, TSDB storage engine, Service Discovery, scrape targets |
| Dia 52 | Exporters & System Metrics | Node Exporter, Postgres Exporter, Redis Exporter, custom `/metrics` endpoints |
| Dia 53 | PromQL Analytical Querying | Instant vs Range vectors, `rate()`, `irate()`, aggregations, histograms |
| Dia 54 | Grafana Dashboards as Code | Dynamic variables, dashboard provisioning, visualization panels |
| Dia 55 | Alertmanager & Notification Routing | Alert rules, grouping, inhibition, silencing, webhook notifications |
| Dia 56 | Week 8 Final Challenge | End-to-end Observability stack deployed on Roxs Voting App with alerting |

---

## Directory Structure

```
daily-exercises/semana-8/
├── README.md           # Semana 8 module overview and roadmap
├── dia-50/README.md    # Observability fundamentals (USE, RED, Three Pillars)
├── dia-51/README.md    # Prometheus server architecture and TSDB internals
├── dia-52/README.md    # Infrastructure and database exporters deployment
├── dia-53/README.md    # PromQL query language deep-dive and rate calculations
├── dia-54/README.md    # Grafana dashboard visualization and JSON provisioning
├── dia-55/README.md    # Alertmanager rule evaluation and notification routing
└── dia-56/README.md    # Week 8 Capstone: Full production observability stack
```
