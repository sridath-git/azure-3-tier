## Runtime Operations Scripts
This repo includes small operational scripts to start/stop/restart/scale services and to prove backup configuration.
use this chmod +x scripts/*.sh

- `scripts/ops.sh` – start/stop/restart/scale/list instances/autoscale
- `scripts/backup-proof.sh` – prints PostgreSQL automated backup retention configuration

Run (replace placeholders via env vars):
```bash
export RG="<resource-group-name>"
export WEB_APP="<web-app-name>"
export API_APP="<api-app-name>"
export PG_NAME="<postgres-server-name>"

./scripts/ops.sh instances
./scripts/backup-proof.sh
./scripts/ops.sh status
./scripts/ops.sh restart
./scripts/ops.sh stop
./scripts/ops.sh start
./scripts/ops.sh instances
./scripts/ops.sh scale 2
./scripts/ops.sh scale 3
./scripts/ops.sh autoscale-list
./scripts/backup-proof.sh
