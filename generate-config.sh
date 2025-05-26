
#!/bin/bash

# File paths
ENV_FILE=".env"
TEMPLATE_FILE="icecast/icecast.xml.template"
OUTPUT_FILE="icecast/icecast.xml"

echo "🔧 Generating icecast.xml from template..."

# Check if files exist
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: $ENV_FILE not found!"
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Error: $TEMPLATE_FILE not found!"
    exit 1
fi

# Load variables from .env
set -a  # automatically export all variables
source "$ENV_FILE"
set +a

# Check required variables
if [ -z "$ICECAST_ADMIN_PASSWORD" ] || [ -z "$ICECAST_SOURCE_PASSWORD" ]; then
    echo "❌ Error: Required environment variables not found in $ENV_FILE"
    echo "Required: ICECAST_ADMIN_PASSWORD, ICECAST_SOURCE_PASSWORD"
    exit 1
fi

# Create directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Generate configuration file
envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"

# Check generation success
if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
    echo "✅ Successfully generated $OUTPUT_FILE"
    echo "📊 File size: $(stat -c%s "$OUTPUT_FILE") bytes"
    echo "🔐 Passwords have been substituted from $ENV_FILE"
else
    echo "❌ Error: Failed to generate $OUTPUT_FILE"
    exit 1
fi