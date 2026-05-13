#!/bin/sh
# Script: create_k8s_secrets.sh
# Description: Create Kubernetes secrets from GitHub secrets for deployment

set -e

SECRET_NAME="mia-platform"
ENV_SECRET_PREFIX="$1"
COMMON_SECRET_PREFIX="$2"
KUBE_URL="$3"
KUBE_TOKEN="$4"
KUBE_NAMESPACE="$5"
SECRETS_JSON="$6"

SECRET_ARGS=""
SECRET_COUNT=0

echo "Processing secrets with prefixes: ${ENV_SECRET_PREFIX} and ${COMMON_SECRET_PREFIX}"

for key in $(echo "$SECRETS_JSON" | jq -r \
  --arg env_prefix "$ENV_SECRET_PREFIX" \
  --arg common_prefix "$COMMON_SECRET_PREFIX" \
  'keys[] | select(startswith($env_prefix) or startswith($common_prefix))' \
  2>/dev/null); do

  SECRET_VALUE=$(echo "$SECRETS_JSON" | jq -r \
    --arg k "$key" \
    '.[$k]' \
    2>/dev/null)

  if [ -n "$SECRET_VALUE" ] && [ "$SECRET_VALUE" != "null" ]; then
    echo "Found secret key: $key"
    case "$key" in
      ${ENV_SECRET_PREFIX}*)
        echo " -> Matched environment prefix, removing: ${ENV_SECRET_PREFIX}"
        SECRET_KEY_NAME=${key#"$ENV_SECRET_PREFIX"}
        ;;
      ${COMMON_SECRET_PREFIX}*)
        echo " -> Matched common prefix, removing: ${COMMON_SECRET_PREFIX}"
        SECRET_KEY_NAME=${key#"$COMMON_SECRET_PREFIX"}
        ;;
      *)
        echo " -> Skipping non-Kubernetes secret."
        continue
        ;;
    esac
    SECRET_KEY_NAME=$(echo "$SECRET_KEY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
    echo " -> Transformed to Kubernetes key: ${SECRET_KEY_NAME}"
    SECRET_ARGS="$SECRET_ARGS --from-literal=${SECRET_KEY_NAME}=$SECRET_VALUE"
    SECRET_COUNT=$((SECRET_COUNT + 1))
  fi
done

echo "Total secrets to be created: $SECRET_COUNT"

if [ "$SECRET_COUNT" -gt 0 ]; then
  echo "Creating/updating secret '${SECRET_NAME}' with ${SECRET_COUNT} entries..."
  kubectl create secret generic "${SECRET_NAME}" $SECRET_ARGS --dry-run=client -o yaml | \
    kubectl apply --server "${KUBE_URL}" --certificate-authority "/tmp/ca.pem" --token "${KUBE_TOKEN}" -n "${KUBE_NAMESPACE}" -f -
  if [ $? -eq 0 ]; then
    echo "Secret '${SECRET_NAME}' successfully created/updated."
  else
    echo "Error: Failed to create/update secret '${SECRET_NAME}'"
    exit 1
  fi
else
  echo "No secrets found with prefixes ${ENV_SECRET_PREFIX} or ${COMMON_SECRET_PREFIX}. Skipping secret creation."
fi
