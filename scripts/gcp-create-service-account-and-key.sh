#!/bin/bash

##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
################################################################## GENERATE GCP SERVICE ACCOUNT AND CREATE A NEW KEY ###########################################3#########################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################

#GCP Project-ID
PROJECT='psyched-silicon-405818'

vault_auth_role(){
  #Loading environment variables for Vault Auth
  CONFIG_FILE="../.vault_credentials"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Arquivo de configuração '$CONFIG_FILE' não encontrado!"
    exit 1
  fi

  source "$CONFIG_FILE"

  #Vault Authentication - APPROLE Method
  TOKEN=$(curl -s --insecure --request POST --data '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' $VAULT_ADDR/v1/auth/approle/login | jq '.auth' | grep 'client_token' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^*//g')
  #echo $TOKEN

  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Falha na autenticação do Vault!"
    exit 1
  fi
}

request_key_info(){
  #Input lifetime for new key
  echo "Informe o tempo que a chave gerada permanecerá ativa"
  read -p "Digite o valor em dias, minutos ou horas, exemplo 1d, 1m ou 1h: " TTL
  echo $TTL
}

generate_serviceaccount_key(){
  #Generate Role of Dynamic Cred (Roleset)
  curl -s --insecure --header "X-Vault-Token: $TOKEN" --request POST --data '{"secret_type":"service_account_key","project":"'$PROJECT'","bindings":"resource \"//cloudresourcemanager.googleapis.com/projects/'$PROJECT'\" {roles=[\"roles/viewer\",\"roles/resourcemanager.projectIamAdmin\",\"roles/iam.serviceAccountKeyAdmin\",\"roles/iam.serviceAccountAdmin\"]}"}' $VAULT_ADDR/v1/gcp/roleset/$PROJECT
  
  #Generate Output File with Vault generated account
  curl -s --insecure --header "X-Vault-Token: $TOKEN" --request GET $VAULT_ADDR/v1/gcp/roleset/$PROJECT | jq '.' > ../response/roleset-service-account-$PROJECT.json

  #Generate Output File with Short-Lived Key for Vault generated account
  curl -s --insecure --header "X-Vault-Token: $TOKEN" --request POST --data '{"ttl":"'$TTL'"}' $VAULT_ADDR/v1/gcp/roleset/$PROJECT/key | jq '.' > ../response/roleset-service-account-key-$PROJECT.json

  #Grep Private Key Data in Base64 String
  cat ../response/roleset-service-account-key-$PROJECT.json | jq '.data' | grep 'private_key_data' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^ *//;s/ *$//; s/ * / /g' > test.txt

  #Convert/Generate CredFile Base64 String to Google Credentials File format
  cat test.txt | base64 --decode > ../response/cred-file-roleset-$PROJECT.json
  rm -rf test.txt

  SVCACCOUNT=$(cat ../response/cred-file-roleset-$PROJECT.json | grep 'client_email' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^ *//;s/ *$//; s/ * / /g')
  echo "Foi criado a service account: $SVCACCOUNT com sucesso!"
}

vault_auth_role
request_key_info
generate_serviceaccount_key
