#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
umask 077
mkdir -p .rendered
helm lint chart
helm template lgtm chart --namespace observability --kube-version 1.35.9 "$@" > .rendered/lgtm.yaml
printf '%s\n' 'Rendered .rendered/lgtm.yaml; no cluster contacted.'
