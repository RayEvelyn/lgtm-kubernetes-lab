#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
umask 077
mkdir -p .secrets
chmod 700 .secrets
python3 - <<'PY'
import pathlib,secrets,json,base64,os
path=pathlib.Path('.secrets/grafana-admin.json')
# Never replace a reviewed login/rotation value just because the script is rerun.
fd=os.open(path,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
password=secrets.token_urlsafe(32)
secret={'apiVersion':'v1','kind':'Secret','metadata':{'name':'grafana-admin','namespace':'observability'},'type':'Opaque','data':{'admin-user':base64.b64encode(b'admin').decode(),'admin-password':base64.b64encode(password.encode()).decode()}}
with os.fdopen(fd,'w') as f:json.dump(secret,f,indent=2);f.write('\n')
print('Prepared protected local Secret file; never commit it.')
PY
