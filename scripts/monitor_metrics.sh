#!/bin/bash

# -------------------------
# ✅ CONFIGURATION
# -------------------------

PROM_URL="http://44.243.14.106:32408"
QUERY_200='sum(increase(django_http_responses_total_by_status_view_method_total{status="200", view="home", job="monitoring/my-app-v2"}[1m]))'
QUERY_404='sum(increase(django_http_responses_total_by_status_view_method_total{status="404", view="home", job="monitoring/my-app-v2"}[1m]))'
LOG_FILE="./pipeline_status.log"

# -------------------------
# 📡 PROMETHEUS QUERY FUNCTION
# -------------------------

query_prometheus() {
  local query="$1"
  curl -sG "${PROM_URL}/api/v1/query" --data-urlencode "query=${query}"
}

# -------------------------
# 🔍 FETCH 200 RESPONSES
# -------------------------

echo "🔍 Checking 200 OK responses..."
resp_200=$(query_prometheus "$QUERY_200")

if [[ $(echo "$resp_200" | jq -r .status) != "success" ]]; then
  echo "❌ Failed to fetch 200 status from Prometheus"
  exit 1
fi

count_200=$(echo "$resp_200" | jq '[.data.result[].value[1] | tonumber] | add // 0')
echo "✅ Total 200 OK responses: $count_200"

# -------------------------
# 🔍 FETCH 404 RESPONSES
# -------------------------

echo "🔍 Checking 404 Not Found responses..."
resp_404=$(query_prometheus "$QUERY_404")

if [[ $(echo "$resp_404" | jq -r .status) != "success" ]]; then
  echo "❌ Failed to fetch 404 status from Prometheus"
  exit 1
fi

count_404=$(echo "$resp_404" | jq '[.data.result[].value[1] | tonumber] | add // 0')
echo "⚠️ Total 404 Not Found responses: $count_404"

# -------------------------
# 📝 LOG TO FILE
# -------------------------

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
echo "$timestamp | 200=$count_200 | 404=$count_404" >> "$LOG_FILE"

# -------------------------
# 🚦 PIPELINE DECISION
# -------------------------

if (( count_404 > 1 )); then
  echo "❌ Pipeline FAILED due to $count_404 404 errors!"
  exit 1
else
  echo "✅ Pipeline PASSED with $count_200 successful responses and no 404s."
  exit 0
fi
