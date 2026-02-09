---
name: monitor
description: Read-only infrastructure monitoring. Use when user asks about pod status, deployments, CPU, memory, restarts, 502 errors, slowness, cluster health, or wants to check if environments are running correctly.
allowed-tools:
  - Bash(~/.claude/skills/monitor/*:*)
---

# Monitor Skill

You have **read-only** access to infrastructure monitoring through the `monitor` command. This queries Thanos (Prometheus-compatible API) for Kubernetes metrics.

## Safety Rules

1. **READ-ONLY**: Only reads metrics, cannot modify infrastructure
2. **PRODUCTION DATA**: Treat pod names, IPs, and resource details as sensitive

## Architecture Overview

**Cluster:** EKS `sytex-prd` in AWS prod account (us-east-1), ~24 nodes (Amazon Linux 2023, K8s v1.33)

**Multi-tenant SaaS:** Each tenant runs in its own namespace (`{tenant}-prd`) with:
- `sytex` deployment — Django + uWSGI web application (port 8080)
- `celery-worker` deployment — Celery workers for async tasks
- `sytex-svc` service — ClusterIP service fronting the web pods

**Tenants:** app, claro, ufinet, dt, adc, atis, exsei, integrar, torresec, tote, demo, claro-br, alfred

**Routing:** AWS ALB → each tenant has its own subdomain:
- `app.sytex.io`, `claro.sytex.io`, `dt.sytex.io`, `ufinet.sytex.io`, `adc.sytex.io`, etc.
- `app-prd` also serves: `batcom.sytex.io`, `powergen.sytex.io`, `telefonica.sytex.io`, `telrap.sytex.io`

**Database:** Shared RDS Aurora cluster with per-tenant databases (`sytex_app`, `sytex_claro`, `sytex_adc`, etc.)

**Message broker:** RabbitMQ (for Celery task queues)

**Caching:** Redis

**Autoscaling:**
- KEDA manages HPAs for high-traffic tenants: `app-prd`, `claro-prd`, `demo-prd`
- Other tenants use standard HPA
- Typical ranges: `app-prd` sytex 3-65 pods, celery-worker 1-30; `claro-prd` sytex 5-60

**Observability stack:** Prometheus + Thanos, Grafana Loki (logs), Grafana Tempo (traces), OpenTelemetry Collector

## Commands

### Quick Overview
```bash
monitor status
```
Shows desired vs available pods per configured environment. Start here.

### Pod Details
```bash
monitor pods <env>
```
Shows deployment readiness, pod phases (Running/Failed/Pending), and recent container restarts.

```bash
monitor pods app
monitor pods claro
monitor pods dt
```

### Custom PromQL
```bash
monitor query '<promql>'
```
Run any PromQL query. See examples below.

### Utility
```bash
monitor envs    # List configured environments
monitor test    # Test connectivity, list all namespaces
```

## Available Metrics

**What you CAN query:**
- Pod/deployment status (replicas, phases, restarts, ready conditions)
- Container resources (CPU usage, memory usage/limits, OOM events, network I/O)
- HPA status (current/desired/min/max replicas, scaling conditions)
- Node status (capacity, allocatable resources, conditions)
- Kubernetes objects (services, ingresses, jobs, configmaps)

**What you CANNOT query (not in Thanos):**
- Application metrics (no Django/uWSGI/Celery instrumentation)
- ALB request metrics (HTTP status codes, latency) — check ALB in AWS console
- RDS metrics (connections, CPU, IOPS) — check Performance Insights or CloudWatch
- RabbitMQ queue depth — check RabbitMQ management UI
- Redis metrics — not scraped

## Troubleshooting Playbooks

### "There are 502 errors on {tenant}"

502s typically mean pods aren't ready or are crashing. Investigate:

```bash
# 1. Check pod status — are all pods ready?
monitor pods {tenant}

# 2. Check if pods are being OOM-killed
monitor query 'increase(container_oom_events_total{namespace="{tenant}-prd"}[1h])'

# 3. Check container restarts (crashes)
monitor query 'increase(kube_pod_container_status_restarts_total{namespace="{tenant}-prd"}[1h]) > 0'

# 4. Check if pods are in CrashLoopBackOff or waiting
monitor query 'kube_pod_container_status_waiting_reason{namespace="{tenant}-prd"}'

# 5. Check if HPA is maxed out (demand exceeds capacity)
monitor query 'kube_horizontalpodautoscaler_status_current_replicas{namespace="{tenant}-prd"}'
monitor query 'kube_horizontalpodautoscaler_spec_max_replicas{namespace="{tenant}-prd"}'
```

If pods look healthy, the issue may be upstream (ALB target group health, RDS saturation, or application-level errors in Sentry).

### "Slowness / high latency on {tenant}"

```bash
# 1. Check CPU throttling (pods hitting CPU limits)
monitor query 'rate(container_cpu_cfs_throttled_periods_total{namespace="{tenant}-prd", container="sytex"}[5m]) / rate(container_cpu_cfs_periods_total{namespace="{tenant}-prd", container="sytex"}[5m])'

# 2. Check memory pressure (close to limits = possible GC pressure)
monitor query 'container_memory_working_set_bytes{namespace="{tenant}-prd", container="sytex"} / container_spec_memory_limit_bytes{namespace="{tenant}-prd", container="sytex"}'

# 3. Check CPU usage vs requests
monitor query 'rate(container_cpu_usage_seconds_total{namespace="{tenant}-prd", container="sytex"}[5m])'

# 4. Check if HPA is scaling up (load increase)
monitor query 'kube_horizontalpodautoscaler_status_desired_replicas{namespace="{tenant}-prd"}'
monitor query 'kube_horizontalpodautoscaler_status_current_replicas{namespace="{tenant}-prd"}'

# 5. Check celery worker queue backlog (workers may be overwhelmed)
monitor query 'kube_deployment_spec_replicas{namespace="{tenant}-prd", deployment="celery-worker"}'
monitor query 'kube_deployment_status_replicas_available{namespace="{tenant}-prd", deployment="celery-worker"}'
```

If CPU throttling is high, pods need more CPU limits. If memory is near 100%, pods may need more memory. If HPA is at max, the cluster may need scaling policy changes.

### "Pod crashes / restarts in {tenant}"

```bash
# 1. Which containers are restarting?
monitor query 'increase(kube_pod_container_status_restarts_total{namespace="{tenant}-prd"}[1h]) > 0'

# 2. Is it OOM?
monitor query 'increase(container_oom_events_total{namespace="{tenant}-prd"}[1h])'

# 3. What's the pod status?
monitor query 'kube_pod_status_phase{namespace="{tenant}-prd"} == 1'

# 4. Any pods in waiting state (CrashLoopBackOff, ImagePullBackOff)?
monitor query 'kube_pod_container_status_waiting_reason{namespace="{tenant}-prd"}'
```

### "Check overall cluster health"

```bash
# 1. Quick status of all environments
monitor status

# 2. Node status — any NotReady?
monitor query 'kube_node_status_condition{condition="Ready", status="true"}'

# 3. Node resource pressure
monitor query 'kube_node_status_condition{condition="MemoryPressure", status="true"}'
monitor query 'kube_node_status_condition{condition="DiskPressure", status="true"}'

# 4. Failed pods across all namespaces
monitor query 'kube_pod_status_phase{phase="Failed"} == 1'

# 5. Pending pods (can't be scheduled)
monitor query 'kube_pod_status_phase{phase="Pending"} == 1'
```

## Useful PromQL Examples

```bash
# CPU usage per pod (cores)
monitor query 'sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="{ns}", container="sytex"}[5m]))'

# Memory usage per pod (MB)
monitor query 'sum by (pod) (container_memory_working_set_bytes{namespace="{ns}", container="sytex"}) / 1024 / 1024'

# Network receive rate per pod (bytes/sec)
monitor query 'sum by (pod) (rate(container_network_receive_bytes_total{namespace="{ns}"}[5m]))'

# Top 5 pods by CPU
monitor query 'topk(5, sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="{ns}"}[5m])))'

# Top 5 pods by memory
monitor query 'topk(5, sum by (pod) (container_memory_working_set_bytes{namespace="{ns}"}))'

# Container restart count (total, not rate)
monitor query 'kube_pod_container_status_restarts_total{namespace="{ns}"}'

# HPA summary for a namespace
monitor query 'kube_horizontalpodautoscaler_status_current_replicas{namespace="{ns}"}'

# All deployments across all tenant namespaces
monitor query 'kube_deployment_spec_replicas{namespace=~".*-prd"}'
```

Replace `{ns}` with the actual namespace (e.g., `app-prd`, `claro-prd`).

## Workflow

1. **Start with `monitor status`** — quick health check across all environments
2. **Drill down with `monitor pods <env>`** — see deployment details, restarts, pod phases
3. **Investigate with `monitor query`** — CPU, memory, throttling, OOM, HPA status
4. **Cross-reference with other tools:**
   - **Sentry** for application errors and stack traces
   - **Database skill** for RDS query performance
   - ALB metrics and RDS Performance Insights are in AWS Console (not accessible via this skill)

## Limitations

- No EU cluster metrics yet (pending separate Thanos endpoint)
- No application-level metrics (Django, uWSGI, Celery are not instrumented for Prometheus)
- No ALB/ingress request metrics (AWS ALB metrics are in CloudWatch, not Prometheus)
- No RDS, Redis, or RabbitMQ metrics in Thanos
