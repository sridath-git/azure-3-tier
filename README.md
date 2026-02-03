# Toptal 3-Tier Continuous Delivery
   
   
## Verification Guide (End-to-End)
This README provides an end-to-end, CLI-driven verification checklist for the **Toptal 3‑Tier architecture** (Web → API → PostgreSQL) deployed on Azure. 


## 0. Set variables once

```bash
RG="Resource group"
WEB_APP="webapp name"
API_APP="api app name"
PG_NAME="pg name"
FD_PROFILE="front door name"
FD_ENDPOINT="front door endpoint"
SLOT="slot name"
```

```bash
SUB_ID=$(az account show --query id -o tsv)
echo "Subscription: $SUB_ID"
```

---

## 1. Show all resources created (proof of infra)

List all resources in the resource group:

```bash
az resource list -g "$RG" -o table
```

List key resource types explicitly:

```bash
az webapp list -g "$RG" -o table
az postgres flexible-server list -g "$RG" -o table
az monitor log-analytics workspace list -g "$RG" -o table

az monitor app-insights component show -g "$RG" -a "${WEB_APP}-ai" -o table 2>/dev/null || true
az monitor app-insights component show -g "$RG" -a "${API_APP}-ai" -o table 2>/dev/null || true
```

---

## 2. Public endpoints: Web + API (prod + slot)

### Web

```bash
curl -I "https://${WEB_APP}.azurewebsites.net/"
curl -I "https://${WEB_APP}-${SLOT}.azurewebsites.net/"
```

### API health

```bash
curl -i "https://${API_APP}.azurewebsites.net/health"
curl -i "https://${API_APP}-${SLOT}.azurewebsites.net/health"
```

### API → DB health

```bash
curl -i "https://${API_APP}.azurewebsites.net/health/db"
curl -i "https://${API_APP}-${SLOT}.azurewebsites.net/health/db"
```

---

## 3. Deployment slots exist + slot swap concept

Show slots:

```bash
az webapp deployment slot list -g "$RG" -n "$WEB_APP" -o table
az webapp deployment slot list -g "$RG" -n "$API_APP" -o table
```

Show slot-specific app settings (optional):

```bash
az webapp config appsettings list -g "$RG" -n "$API_APP" --slot "$SLOT" -o table
az webapp config appsettings list -g "$RG" -n "$WEB_APP" --slot "$SLOT" -o table
```

---

## 4. Confirm expected container images are running

```bash
az webapp config container show -g "$RG" -n "$WEB_APP" -o jsonc
az webapp config container show -g "$RG" -n "$API_APP" -o jsonc

az webapp config container show -g "$RG" -n "$WEB_APP" --slot "$SLOT" -o jsonc
az webapp config container show -g "$RG" -n "$API_APP" --slot "$SLOT" -o jsonc
```

---

## 5. High availability: multiple running instances

```bash
az webapp list-instances -g "$RG" -n "$WEB_APP" -o table
az webapp list-instances -g "$RG" -n "$API_APP" -o table
```

**Expected:** at least 2 rows with `State=READY`.

---

## 6. App Service Plan scale (minimum instances)

Find the App Service Plan:

```bash
PLAN_ID=$(az webapp show -g "$RG" -n "$WEB_APP" --query "serverFarmId" -o tsv)
echo "$PLAN_ID"
```

will show plan details

```bash
az appservice plan show --ids "$PLAN_ID" -o jsonc
```

Current worker count:

```bash
az appservice plan show --ids "$PLAN_ID" --query "numberOfWorkers" -o tsv
```

---

## 7. Autoscale configuration (if enabled)

```bash
az monitor autoscale list -g "$RG" -o table
az monitor autoscale list -g "$RG" -o jsonc
```

---

## 8. VNet Integration proof (API tier)

```bash
az webapp vnet-integration list -g "$RG" -n "$API_APP" -o table
az webapp vnet-integration list -g "$RG" -n "$API_APP" --slot "$SLOT" -o table
```

(Optional, if Web is integrated):

```bash
az webapp vnet-integration list -g "$RG" -n "$WEB_APP" -o table || true
```

---

## 9. Database is private (no public access)

Public network access:

```bash
az postgres flexible-server show -g "$RG" -n "$PG_NAME" --query "network.publicNetworkAccess" -o tsv
```

**Expected:** `Disabled`.

DB FQDN (reference only):

```bash
az postgres flexible-server show -g "$RG" -n "$PG_NAME" --query "fullyQualifiedDomainName" -o tsv
```

Private networking artifacts:

```bash
az network private-endpoint list -g "$RG" -o table
az network private-dns zone list -g "$RG" -o table
az network private-dns link vnet list -g "$RG" -o table || true
```

---

## 10. Web → DB access is intentionally blocked (negative proof)

Web app has no DB credentials:

```bash
az webapp config appsettings list -g "$RG" -n "$WEB_APP" -o table
```

DB still has no public access:

```bash
az postgres flexible-server show -g "$RG" -n "$PG_NAME" --query "network.publicNetworkAccess" -o tsv
```

---

## 11. Centralized logging (Log Analytics)

Show workspace:

```bash
az monitor log-analytics workspace list -g "$RG" -o table
LAW_ID=$(az monitor log-analytics workspace list -g "$RG" --query "[0].id" -o tsv)
echo "$LAW_ID"
```

Diagnostic settings attached:

```bash
az monitor diagnostic-settings list --resource "$(az webapp show -g "$RG" -n "$WEB_APP" --query id -o tsv)" -o jsonc
az monitor diagnostic-settings list --resource "$(az webapp show -g "$RG" -n "$API_APP" --query id -o tsv)" -o jsonc
az monitor diagnostic-settings list --resource "$(az postgres flexible-server show -g "$RG" -n "$PG_NAME" --query id -o tsv)" -o jsonc
```

Live log streaming:

```bash
az webapp log tail -g "$RG" -n "$WEB_APP"
az webapp log tail -g "$RG" -n "$API_APP"

az webapp log tail -g "$RG" -n "$WEB_APP" --slot "$SLOT"
az webapp log tail -g "$RG" -n "$API_APP" --slot "$SLOT"
```

---

## 12. Application Insights verification

```bash
az monitor app-insights component show -g "$RG" -a "${WEB_APP}-ai" -o table 2>/dev/null || true
az monitor app-insights component show -g "$RG" -a "${API_APP}-ai" -o table 2>/dev/null || true
```

Connection string present:

```bash
az webapp config appsettings list -g "$RG" -n "$WEB_APP" \
  --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING' || name=='APPINSIGHTS_INSTRUMENTATIONKEY']" -o table

az webapp config appsettings list -g "$RG" -n "$API_APP" \
  --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING' || name=='APPINSIGHTS_INSTRUMENTATIONKEY']" -o table
```

---

## 13. CDN / Front Door verification (Web only)

Get Front Door hostname:

```bash
FD_ENDPOINT_ID=$(az resource list -g "$RG" \
  --resource-type "Microsoft.Cdn/profiles/afdEndpoints" \
  --query "[0].id" -o tsv)

echo "$FD_ENDPOINT_ID"

FD_HOST=$(az resource show --ids "$FD_ENDPOINT_ID" --query "properties.hostName" -o tsv)
echo "$FD_HOST"
```

Test Front Door → Web:

```bash
curl -I "https://${FD_HOST}/"
```

Routes and origins:

```bash
az afd route list --resource-group "$RG" --profile-name "$FD_PROFILE" --endpoint-name "$FD_ENDPOINT" -o table
az afd origin-group list --resource-group "$RG" --profile-name "$FD_PROFILE" -o table
az afd origin list --resource-group "$RG" --profile-name "$FD_PROFILE" --origin-group-name "${WEB_APP}-og" -o table 2>/dev/null || true
```

---

## 14. Backup proof (PostgreSQL)

```bash
az postgres flexible-server show -g "$RG" -n "$PG_NAME" \
  --query "{backupRetentionDays:backup.backupRetentionDays, geoRedundantBackup:backup.geoRedundantBackup}" -o jsonc
```

---

## 15. Health troubleshooting (quick checks)

Current state:

```bash
az webapp show -g "$RG" -n "$WEB_APP" --query "state" -o tsv
az webapp show -g "$RG" -n "$API_APP" --query "state" -o tsv
```

Restart if required:

```bash
az webapp restart -g "$RG" -n "$WEB_APP"
az webapp restart -g "$RG" -n "$API_APP"
```
## Log Analytics (KQL) – Verification Queries

**Azure Portal → Log Analytics Workspace → Logs**
## 16. App Service HTTP request logs (Web + API)

```kql
AppServiceHTTPLogs
| where TimeGenerated > ago(24h)
| project TimeGenerated, AppName, SiteName, ScStatus, CsMethod, CsUriStem, TimeTaken
| order by TimeGenerated desc
```

## 17. App Service application logs (application / console logs)

```kql
AppServiceAppLogs
| where TimeGenerated > ago(24h)
| project TimeGenerated, AppName, Level, Message
| order by TimeGenerated desc
```

## 18. App Service container stdout / stderr logs

```kql
AppServiceConsoleLogs
| where TimeGenerated > ago(24h)
| project TimeGenerated, AppName, LogLevel, Message
| order by TimeGenerated desc
```

## 19. App Service platform logs

```kql
AppServicePlatformLogs
| where TimeGenerated > ago(24h)
| project TimeGenerated, AppName, Level, Message
| order by TimeGenerated desc
```

## 20. PostgreSQL logs (Flexible Server)

```kql
AzureDiagnostics
| where ResourceType == "POSTGRESQLFLEXIBLESERVERS"
| where TimeGenerated > ago(24h)
| project TimeGenerated, Category, Message
| order by TimeGenerated desc
```

## 21. Database metrics (connections, CPU, storage)

```kql
AzureMetrics
| where ResourceProvider == "MICROSOFT.DBFORPOSTGRESQL"
| where TimeGenerated > ago(24h)
| project TimeGenerated, MetricName, Total, Average, Maximum
| order by TimeGenerated desc
```

## 22. App Service metrics (CPU, memory, requests)

```kql
AzureMetrics
| where ResourceProvider == "MICROSOFT.WEB"
| where TimeGenerated > ago(24h)
| project TimeGenerated, Resource, MetricName, Average, Maximum
| order by TimeGenerated desc
```

## 23. Errors across all tiers (unified view)

```kql
union AppServiceAppLogs, AppServiceConsoleLogs
| where TimeGenerated > ago(24h)
| where Level in ("Error", "Critical")
| project TimeGenerated, AppName, Level, Message
| order by TimeGenerated desc
```

## 24. Traffic volume over time (historical trend)

```kql
AppServiceHTTPLogs
| where TimeGenerated > ago(24h)
| summarize Requests=count() by bin(TimeGenerated, 5m), AppName
| order by TimeGenerated asc
```
---

## Outcome

This verification proves:

* Proper 3‑tier separation (Web → API → DB)
* Private database access
* High availability and scaling
* Safe deployments using slots
* Centralized logging and monitoring
* CDN in front of the Web tier

