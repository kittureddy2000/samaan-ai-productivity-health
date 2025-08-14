#!/bin/bash

# Replace GOOGLE_CLIENT_ID placeholder in web/index.html during build
# Usage: ./scripts/replace-web-client-id.sh <client_id>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <google_client_id>"
    exit 1
fi

CLIENT_ID="$1"

# Replace the placeholder in web/index.html
if [ -f "web/index.html" ]; then
    sed -i.bak "s/{{GOOGLE_CLIENT_ID}}/$CLIENT_ID/g" web/index.html
    echo "✅ Replaced GOOGLE_CLIENT_ID in web/index.html"
else
    echo "❌ web/index.html not found"
    exit 1
fi