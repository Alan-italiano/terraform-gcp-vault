#!/bin/bash
CONFIG_FILE=".vault_credentials"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Arquivo de configuração '$CONFIG_FILE' não encontrado!"
    exit 1
fi

source "$CONFIG_FILE"

TOKEN=$(curl -s --insecure --request POST --data "{\"role_id\":\"$ROLE_ID\", \"secret_id\":\"$SECRET_ID\"}" \
    "$VAULT_ADDR/v1/auth/approle/login" | jq -r '.auth.client_token')

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Falha na autenticação do Vault!"
    exit 1
fi

GCP_KEY_JSON=$(curl -s --insecure --header "X-Vault-Token: $TOKEN" "$VAULT_ADDR/v1/gcp/key/psyched-silicon-405818" | jq -r '.data.private_key_data')

if [[ -z "$GCP_KEY_JSON" || "$GCP_KEY_JSON" == "null" ]]; then
    echo "Não foi possível obter a chave JSON da Service Account!"
    exit 1
fi

echo "$GCP_KEY_JSON" | base64 --decode > gcp-key.json
echo "Chave salva em gcp-key.json"

export TF_VAR_gcp_credentials_file="gcp-key.json"

echo "Inicializando o Terraform"
tofu init

echo "Executando o Terraform"
tofu apply -auto-approve -var="project_id="
