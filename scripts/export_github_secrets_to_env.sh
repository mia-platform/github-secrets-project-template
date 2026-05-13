#!/bin/sh
# Script: export_github_secrets_to_env.sh
# Description: Export all GitHub secrets to $GITHUB_ENV with their original names

set -e

SECRETS_JSON="$1"


if [ -z "$SECRETS_JSON" ]; then
  echo "Error: SECRETS_JSON is empty."
  exit 1
fi

# Debug: print the first 100 chars of the input
echo "DEBUG: SECRETS_JSON (first 100 chars):"
echo "$SECRETS_JSON" 
echo

# Check if input is valid JSON (keys quoted)
if ! echo "$SECRETS_JSON" | jq empty 2>/dev/null; then
  echo "Input is not valid JSON. Attempting to convert to valid JSON..."
  # Try to convert pseudo-JSON to valid JSON (quote keys)
  SECRETS_JSON=$(echo "$SECRETS_JSON" | \
    sed -E 's/([,{]\s*)([A-Za-z0-9_\-]+):/\1"\2":/g')
  # Print the fixed JSON for debug
  echo "Fixed JSON (first 100 chars):"
  echo "$SECRETS_JSON" | head -c 100
  echo
  # Validate again
  if ! echo "$SECRETS_JSON" | jq empty 2>/dev/null; then
    echo "Error: Could not convert input to valid JSON."
    exit 2
  fi
fi


for key in $(echo "$SECRETS_JSON" | jq -r 'keys[]'); do
  # Try to extract the value, skip if it fails
  value=$(echo "$SECRETS_JSON" | jq -r --arg k "$key" '.[$k]' 2>/dev/null || true)
  if [ $? -ne 0 ]; then
    echo "[WARN] Unable to extract value for key: $key, skipping."
    continue
  fi
  # Skip masked, unavailable, or empty secrets
  trimmed_key=$(echo "$key" | tr -d '[:space:]')
  trimmed_value=$(echo "$value" | tr -d '[:space:]')
  if [ -n "$trimmed_value" ] && [ "$trimmed_value" != "null" ] && [ "$trimmed_value" != "***" ] && [ "$trimmed_value" != "\"***\"" ] && [ "$trimmed_key" != "***" ]; then
    echo "$key=$value" >> "$GITHUB_ENV"
    echo "Exported secret: $key"
  elif [ "$trimmed_value" = "***" ] || [ "$trimmed_value" = "\"***\"" ] || [ -z "$trimmed_value" ] || [ "$trimmed_key" = "***" ]; then
    echo "[WARN] Secret $key is masked, empty, not available, or key is invalid, skipping."
  fi
done

echo "All GitHub secrets exported to GITHUB_ENV."
