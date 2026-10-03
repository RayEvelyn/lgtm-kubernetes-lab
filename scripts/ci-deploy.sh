#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
umask 077
[[ ${DEPLOY_ENABLED:-} == true && ${HOMELAB_PRIVATE_REPOSITORY:-} == true ]] || exit 1
case ${HOMELAB_ACTION:-plan} in
 plan) ./scripts/render.sh; exit 0;;
 deploy) ;;
 *) exit 1;;
esac
: "${HOMELAB_KUBECONFIG:?Provide a dedicated namespace-scoped cluster identity}"
: "${EXPECTED_CONTEXT:?Set the exact workload context}"
: "${STORAGE_CLASS:?Set the persistent storage class}"
: "${GRAFANA_ADMIN_PASSWORD:?Provide a stable protected Grafana password}"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
printf '%s\n' "$HOMELAB_KUBECONFIG" > "$work/kubeconfig"
export KUBECONFIG="$work/kubeconfig" GRAFANA_SECRET_FILE="$work/grafana.json"
python3 - <<'PYSECRET'
import json,os
from pathlib import Path
v={'apiVersion':'v1','kind':'Secret','metadata':{'name':'grafana-admin','namespace':'observability'},'type':'Opaque','stringData':{'admin-user':'admin','admin-password':os.environ['GRAFANA_ADMIN_PASSWORD']}}
Path(os.environ['GRAFANA_SECRET_FILE']).write_text(json.dumps(v))
PYSECRET
unset HOMELAB_KUBECONFIG GRAFANA_ADMIN_PASSWORD
export HELM_CONFIG_HOME="$work/helm/config" HELM_CACHE_HOME="$work/helm/cache" HELM_DATA_HOME="$work/helm/data"
export LAB_INSTALL_ACK=yes
./scripts/install.sh
