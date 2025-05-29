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
echo "🔒 Protegiendo la rama '$BRANCH' del repositorio '$OWNER/$REPO'..."

response=$(curl -s -w "\n%{http_code}" \
  -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/branches/$BRANCH/protection" \
  -d @- <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
)

# === MANEJAR RESPUESTA ===
body=$(echo "$response" | head -n -1)
status=$(echo "$response" | tail -n1)

if [ "$status" = "200" ]; then
  echo "✅ Rama protegida exitosamente."
else
  echo "❌ Error $status al proteger rama:"
  echo "$body"
fi
