#!/usr/bin/env bash
set -euo pipefail

# Runtime operations script for Web and API App Services

RG="<resource-group-name>"
WEB_APP="<web-app-name>"
API_APP="<api-app-name>"

ACTION="${1:-help}"

case "$ACTION" in
  status)
    az webapp show -g "$RG" -n "$WEB_APP" --query "state" -o tsv
    az webapp show -g "$RG" -n "$API_APP" --query "state" -o tsv
    ;;

  restart)
    az webapp restart -g "$RG" -n "$WEB_APP"
    az webapp restart -g "$RG" -n "$API_APP"
    ;;

  start)
    az webapp start -g "$RG" -n "$WEB_APP"
    az webapp start -g "$RG" -n "$API_APP"
    ;;

  stop)
    az webapp stop -g "$RG" -n "$WEB_APP"
    az webapp stop -g "$RG" -n "$API_APP"
    ;;

  *)
    echo "Usage:"
    echo "  ./ops.sh status"
    echo "  ./ops.sh start"
    echo "  ./ops.sh stop"
    echo "  ./ops.sh restart"
    ;;
esac
