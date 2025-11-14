#!/bin/bash
set -e

VAULT_ADDR=${VAULT_ADDR:-"http://127.0.0.1:8200"}
VAULT_TOKEN=${VAULT_TOKEN:-"root"}

echo "📁 Initializing Vault policies..."

# App policy
vault policy write app-policy - <<EOF
path "secret/data/luks/prod/*" {
  capabilities = ["read"]
}

path "secret/data/app/*" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

# Ansible policy
vault policy write ansible-policy - <<EOF
path "secret/data/luks/prod/*" {
  capabilities = ["read", "create", "update"]
}

path "auth/token/create" {
  capabilities = ["update"]
  required_parameters = ["policies"]
}
EOF

# GitHub Actions policy
vault policy write github-actions-policy - <<EOF
path "secret/data/luks/prod/*" {
  capabilities = ["read", "create", "update"]
}

path "auth/approle/login" {
  capabilities = ["update"]
}
EOF

echo "🔗 Configuring AppRole authentication..."

vault auth enable approle

# Create AppRole for GitHub Actions
vault write auth/approle/role/github-actions \
  token_policies="github-actions-policy" \
  token_ttl=1h \
  token_max_ttl=4h

# Get AppRole ID and Secret ID
ROLE_ID=$(vault read -format=json auth/approle/role/github-actions/role-id | jq -r '.data.role_id')
SECRET_ID=$(vault write -format=json -f auth/approle/role/github-actions/secret-id | jq -r '.data.secret_id')

echo "🔑 GitHub Actions AppRole credentials:"
echo "VAULT_ROLE_ID=${ROLE_ID}"
echo "VAULT_SECRET_ID=${SECRET_ID}"
echo ""
echo "📋 Add these as GitHub Secrets in your repository settings!"

echo "✅ Vault initialization completed successfully!"
