#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
: "${KUBECONFIG:?Select the intended workload cluster kubeconfig}"
: "${EXPECTED_CONTEXT:?Set the exact reviewed Kubernetes context}"
: "${STORAGE_CLASS:?Select an existing provisioner such as local-path in K3s}"
[[ ${LAB_INSTALL_ACK:-} == yes ]] || { echo 'Set LAB_INSTALL_ACK=yes only after manifest/context review.' >&2; exit 1; }
[[ $(kubectl config current-context) == "$EXPECTED_CONTEXT" ]] || { echo 'Kubernetes context mismatch.' >&2; exit 1; }
secret_file=${GRAFANA_SECRET_FILE:-.secrets/grafana-admin.json}
[[ -f $secret_file ]] || { echo 'Run prepare-secret.sh and review private local permissions first.' >&2; exit 1; }
kubectl get storageclass "$STORAGE_CLASS"
if kubectl get namespace observability >/dev/null 2>&1; then
  [[ $(kubectl get namespace observability -o jsonpath='{.metadata.labels.app\.kubernetes\.io/part-of}') == lgtm-lab ]] || { echo 'Existing namespace is not owned by this lab; refusing.' >&2; exit 1; }
else
  kubectl apply -f manifests/namespace.yaml
fi
kubectl -n observability apply -f "$secret_file"
helm upgrade --install lgtm chart --namespace observability --set-string "storageClass=$STORAGE_CLASS" --wait --timeout 15m
printf '%s\n' 'Check signals end-to-end before calling this installation verified.'
