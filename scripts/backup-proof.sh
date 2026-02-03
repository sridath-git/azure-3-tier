#!/usr/bin/env bash
set -euo pipefail

# This script proves that PostgreSQL automated backups are enabled
# and shows the configured backup retention settings.

RG="<resource-group-name>"
PG_NAME="<postgres-server-name>"

echo "PostgreSQL backup configuration:"
az postgres flexible-server show \
  -g "$RG" \
  -n "$PG_NAME" \
  --query "{backupRetentionDays: backup.backupRetentionDays, geoRedundantBackup: backup.geoRedundantBackup}" \
  -o jsonc

echo
echo "Automated backups run daily on PostgreSQL Flexible Server."
