#!/bin/bash
set -e

# Inject runtime API URLs into /usr/share/nginx/html/config.js
# These are passed as Cloud Run environment variables at deploy time
RECOMMEND_API="${RECOMMEND_API_URL:-http://localhost:8000}"
SEARCH_API="${SEARCH_API_URL:-http://localhost:8080}"

cat > /usr/share/nginx/html/config.js <<EOF
window.__DRS_CONFIG__ = {
  RECOMMEND_API: "${RECOMMEND_API}",
  SEARCH_API: "${SEARCH_API}"
};
EOF

echo "[entrypoint] config.js written: RECOMMEND_API=${RECOMMEND_API} SEARCH_API=${SEARCH_API}"

exec nginx -g "daemon off;"
