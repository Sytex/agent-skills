# Monitor Skill

Read-only infrastructure monitoring. Multiple approaches available depending on access and security requirements.

## Approaches

### Approach A: Grafana API (current implementation)

Query Prometheus/Thanos metrics, Loki logs, and alerts through Grafana's API. Requires a Service Account token and network access to the Grafana workspace.

### Approach B: Direct Thanos/Loki/Tempo endpoints

Query the observability stack directly without going through Grafana. Simpler auth, fewer hops.

**Known endpoints (prod cluster):**

| Service | Endpoint | Status |
|---------|----------|--------|
| Tempo (traces) | `grafana-tempo.sytex.io` | Accessible, no auth, Tempo v2.7.1 |
| Thanos (metrics) | **TBD** — ask infra team | Prometheus-compatible API |
| Loki (logs) | **TBD** — ask infra team | LogQL API |

Tempo is confirmed working. For metrics and logs, get the Thanos Query and Loki endpoints from the infra team.

### Approach C: AWS EKS MCP Server

Use the official [Amazon EKS MCP Server](https://awslabs.github.io/mcp/servers/eks-mcp-server) to give the agent direct access to EKS clusters via the Model Context Protocol. The agent interacts with K8s resources through MCP tools instead of CLI commands.

**Pros:**
- Native integration with Claude/AI agents (MCP protocol)
- AWS IAM authentication (no static tokens)
- Rich toolset: pods, logs, events, CloudWatch metrics, troubleshooting guides
- Read-only mode by default (safe for production)
- No kubectl or custom scripts needed

**Cons:**
- Requires IAM permissions on the EC2 for EKS access
- Requires `aws-auth` ConfigMap or EKS Access Entry to map IAM role to K8s RBAC
- Needs Python 3.10+ and `uv` on the EC2

**Configuration (read-only, for Claude Code or agent):**

```json
{
  "mcpServers": {
    "awslabs.eks-mcp-server": {
      "command": "uvx",
      "args": ["awslabs.eks-mcp-server@latest"],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

To also access logs and events, add `"--allow-sensitive-data-access"` to args.
To enable write operations (NOT recommended for prod), add `"--allow-write"`.

**Available MCP tools (read-only mode):**

| Tool | Description |
|------|-------------|
| `list_k8s_resources` | List pods, deployments, services, etc. with label/field filters |
| `manage_k8s_resource` | Read individual K8s resource details |
| `list_api_versions` | Discover available API versions |
| `get_eks_vpc_config` | VPC configuration details |
| `get_cloudwatch_metrics` | CloudWatch metrics for K8s resources (Container Insights) |
| `get_eks_insights` | Cluster health and upgrade readiness |
| `search_eks_troubleshoot_guide` | Search EKS troubleshooting docs |

**With `--allow-sensitive-data-access`:**

| Tool | Description |
|------|-------------|
| `get_pod_logs` | Retrieve pod logs |
| `get_k8s_events` | Fetch K8s events for resources |
| `get_cloudwatch_logs` | CloudWatch logs for pods, nodes, containers |

**IAM permissions needed (read-only):**
- `eks:DescribeCluster`, `eks:ListClusters`
- `ec2:DescribeSubnets`, `ec2:DescribeSecurityGroups`
- `cloudwatch:GetMetricData` (for metrics)
- `logs:GetLogEvents`, `logs:FilterLogEvents` (for logs, if enabled)

**K8s RBAC:** The EC2's IAM role must be mapped in the cluster via `aws-auth` ConfigMap or EKS Access Entries, with a read-only ClusterRole:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitor-readonly
rules:
- apiGroups: [""]
  resources: ["pods", "services", "namespaces", "events"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list"]
- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitor-readonly-binding
subjects:
- kind: Group
  name: monitor-readonly
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: monitor-readonly
  apiGroup: rbac.authorization.k8s.io
```

Then map the IAM role to the `monitor-readonly` group via EKS Access Entry:
```bash
aws eks create-access-entry --cluster-name CLUSTER_NAME \
  --principal-arn arn:aws:iam::ACCOUNT:role/EC2_ROLE_NAME \
  --kubernetes-groups monitor-readonly
```

---

## Recommendation

| Approach | Complexity | Security | Coverage |
|----------|-----------|----------|----------|
| **A: Grafana** | Medium (SG fix needed) | Good (viewer token) | Metrics + Logs + Alerts |
| **B: Direct endpoints** | Low (already accessible) | Good (network-level) | Metrics + Logs + Traces |
| **C: EKS MCP** | Medium (IAM + RBAC) | Best (IAM + RBAC, no static tokens) | K8s resources + CloudWatch |

**For quick start:** Approach B — direct Thanos/Loki endpoints are already accessible via VPN, no auth config needed.

**For full observability:** Approach A — Grafana gives unified access to everything including alerts.

**For deep K8s access:** Approach C — EKS MCP gives native resource access with proper IAM auth.

Approaches can be combined. For example: B for metrics/logs + C for K8s troubleshooting.

---

## Current Implementation (Approach B - Thanos Direct)

### Requirements

- `jq` for JSON parsing
- `curl` for API calls
- Network access to Thanos endpoint (via VPN)

### Configuration

```
MONITOR_THANOS_URL="https://thanos.sytex.io"
MONITOR_ENVIRONMENTS="app claro ufinet dt adc app_eu"
MONITOR_NAMESPACE_SUFFIX="-prd"
```

### Commands

| Command | Description |
|---------|-------------|
| `status` | Pod status summary for all environments |
| `pods <env>` | Deployment readiness, pod phases, restarts |
| `query <promql>` | Custom PromQL query |
| `envs` | List configured environments |
| `test` | Test Thanos connectivity |

### Network Topology

```
EC2 (dev: 061039787076)
  ├─ VPN (tun0, 192.168.232.0/24) → Prod (324513483688)
  └─ VPC Peering pcx-0eabc21df2fdeeec4 → Shared (585008044454)

Observability endpoints (via VPN/prod network):
  ├─ thanos.sytex.io — Prometheus metrics ✓ (no auth, network-level access)
  ├─ grafana-tempo.sytex.io — Tempo traces ✓ (v2.7.1, no auth)
  └─ loki.sytex.io (TBD) — Logs
```

---

## Grafana (Approach A - Not yet accessible)

The Grafana workspace (`sytex-managed-grafana`, `g-91c6f55778`) is in the **shared account** (`585008044454`) with **VPC-only** access. Currently blocked — security group `sg-057a1b21f34938007` has **no inbound rules**.

**To enable access**, add inbound HTTPS rule:
```bash
aws ec2 authorize-security-group-ingress --profile sytex-shared --region us-east-1 \
  --group-id sg-057a1b21f34938007 \
  --protocol tcp --port 443 --cidr 192.168.232.0/24
```

Service Account `Kadmos` (sa-1-kadmos) with Viewer role is already created.
