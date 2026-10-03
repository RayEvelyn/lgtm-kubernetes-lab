# Local review validation — 2026-10-03

Passed locally:

- Registry manifest inspection for all five version tags; immutable multi-architecture digests pinned in values.
- Helm lint and rendering: 24 objects, no Secret, only ClusterIP Services, five retained PVCs.
- Checksum-verified temporary kubeconform v0.8.0: Kubernetes 1.35 strict schema validation, 24 valid / 0 invalid / 0 errors / 0 skipped. The coordinator independently repeated schema and shell checks.
- Bash syntax for all scripts; coordinator reports ShellCheck passed.
- Loki 3.7.8 binary `-verify-config=true` passed.
- Tempo 3.1.0 binary config verification passed, including corrected persistent paths.
- Mimir 3.2.1 binary parsed the complete config and enumerated modules successfully.
- Formatted Alloy graph validation passed using native 1.20.0 and the exact pinned 1.20.1 container binary. This tests real component names/references, not only formatting.

## Bounded startup attempts and corrections

Temporary local Docker containers had no external network, no host ports, dropped capabilities, restricted CPU/memory, read-only root filesystems and disposable data storage. Each was removed after its short diagnostic window. Existing Kubernetes clusters/services were not contacted.

1. Initial startup exposed Mimir's default relative activity file and Tempo 3's scheduler/live-store defaults outside the intended PVC. Configuration was corrected to put activity tracking, scheduler work cache, live-store WAL and shutdown markers under `/data`.
2. A subsequent Mimir check used the image's default UID against a tmpfs owned by the chart's enforced UID 10001. Corrected the diagnostic to match the manifest user. This was a test-context mismatch, not evidence that the PVC's fsGroup fails.
3. Corrected Tempo started with zero error-level lines in the bounded window. This establishes short local process startup, not sustained readiness, ingestion, retention or Kubernetes convergence.
4. Mimir's first corrected hermetic startup reached its querier lifecycler and stopped because `--network none` has no `eth0`/`en0` address. This failure remains in the local evidence. A later coordinator-requested local bounded diagnostic used a fresh Docker **internal-only** network, matching the pod's available `eth0` without external egress. Mimir stayed running for its 20-second observation window, with no OOM and zero error-level lines. The first readiness command could not run because the distroless image has no `/bin/sh`; this was a diagnostic-tool limitation, not a successful readiness check.

5. A single bounded follow-up used a curl helper on another fresh internal-only network, since the Mimir image intentionally contains no shell. At 30 seconds the HTTP endpoint answered **503**, explicitly `Ingester not ready: waiting for 15s after being ready`. The process remained running, had no OOM and zero error-level lines. This verifies reachable HTTP and identifies a concrete initial readiness grace period; it does **not** establish a passing readiness gate. No additional retries were performed. Both owned diagnostic containers/networks were removed. Sustained Ready status and telemetry collection/query remain isolated-cluster follow-ups.

Sanitized diagnostic logs remain in the ignored `.rendered/` directory for local review. They contain only these empty diagnostic processes, not customer/application payloads. Failed attempts are preserved rather than presented as passing tests.

## Not executed

No Kubernetes apply, Helm install, real Secret preparation, PVC binding, cluster RBAC/NetworkPolicy enforcement, telemetry ingestion, Grafana login, backup/restore or production evaluation occurred. No repository was pushed or published. Static schemas and local config validation do not establish end-to-end functionality. An owner-reviewed isolated cluster test must verify each signal before claiming completion of a deployment.

## Manual private CI additions (2026-10-03)

Local checks passed: actionlint (custom homelab label declared), ShellCheck, every Bash script syntax, GitHub/GitLab YAML parsing, and helper fail-closed behavior without private/enabled deployment flags. Helm lint and manifest rendering passed. The first workflow lint flagged the intentional custom runner label; declaring that label corrected the diagnostic. The initial validation inventory filename was corrected to the existing bare-metal example before final checks. No Terraform plan/apply, SSH bootstrap, real CI deployment or Kubernetes API calls were performed. Runner prerequisites, secrets, TLS/host trust, persistent-state backup and actual first deployment remain unverified. Existing runtime diagnostic limitations above are unchanged.
