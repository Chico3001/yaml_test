#!/bin/bash

# === CONFIGURACIÓN ===
OWNER="chico3001"
REPO="yaml_test"
BRANCH="main"
SECRET_ID="dev/devops/tvazteca_gh"
SECRET_NAME="GITHUb_TOKEN"

# === Obtener token desde AWS Secrets Manager ===
TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --region "us-east-1" \
  --query SecretString \
  --output text \
   | jq -r .$SECRET_NAME)

if [ -z "$TOKEN" ]; then
  echo "❌ No se pudo obtener el token desde AWS Secrets Manager."
  exit 1
fi

# === LLAMADA A LA API ===
echo "🔓 Desprotegiendo la rama '$BRANCH' del repositorio '$OWNER/$REPO'..."

response=$(curl -s -w "\n%{http_code}" \
  -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/branches/$BRANCH/protection"
)

# === MANEJAR RESPUESTA ===
body=$(echo "$response" | head -n -1)
status=$(echo "$response" | tail -n1)

if [ "$status" = "204" ]; then
  echo "✅ Rama protegida exitosamente."
else
  echo "❌ Error $status al proteger rama:"
  echo "$body"
fi
