#!/bin/bash

##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
########################################################## GENERATE SHORT-LIVED KEYS FOR EXISTING GCP SERVICE ACCOUNT ####################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################

request_gcp_info(){
  #Request Existing Service Account
  echo "Informe a conta que será gerado as chaves temporárias?"
  read -p "Digite o nome da conta: " SERVICEACCOUNT

  #Request Project-ID
  echo "Informe o projeto que a conta pertence"
  read -p "Digite o ID do projeto: " PROJECT

  #Increase  for new key
  echo "Informe o tempo que a chave gerada permanecerá ativa"
  read -p "Digite o valor em dias, minutos ou horas, exemplo 1d, 1m ou 1h: " TTL
}

vault_auth_role(){
  #Loading environment variables for Vault Auth
  CONFIG_FILE="../.vault_credentials"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Arquivo de configuração '$CONFIG_FILE' não encontrado!"
    exit 1
  fi

  source "$CONFIG_FILE"

  #Payload Info Variable
  CURL_DATA='{"secret_type":"service_account_key","service_account_email":"'$SERVICEACCOUNT'@'$PROJECT'.iam.gserviceaccount.com"}';
  #echo $CURL_DATA

  #Vault Authentication - APPROLE Method
  TOKEN=$(curl -s --insecure --request POST --data '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' $VAULT_ADDR/v1/auth/approle/login | jq '.auth' | grep 'client_token' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^*//g')
  #echo $TOKEN

  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Falha na autenticação do Vault!"
    exit 1
  fi

  #Generate a role for be able to rotate a short-lied keys for existing service accounts
  ROLE=$(curl -s --insecure --header "X-Vault-Token: $TOKEN" --request POST --data "$CURL_DATA" $VAULT_ADDR/v1/gcp/static-account/$SERVICEACCOUNT-$PROJECT | jq ".") #> output.json
  #echo $ROLE

  if [ -z ${ROLE} ]; then
        echo "Operação executada com sucesso!"
  else
        echo "Falhou na operação, verificar se a service account ou o projeto existem!"
  fi
}

generate_keys(){
  #Generate short-lived secret (Service Account Key)
  KEY=$(curl -s --insecure --header "X-Vault-Token: $TOKEN" --request POST --data '{"key_algorithm":"KEY_ALG_RSA_2048","key_type":"TYPE_GOOGLE_CREDENTIALS_FILE","ttl":"'$TTL'"}' $VAULT_ADDR/v1/gcp/static-account/$SERVICEACCOUNT-$PROJECT/key | jq ".")
  echo $KEY | jq "." > ../response/$SERVICEACCOUNT-key.json

  #Grep Private Key Data in Base64 String
  BASE64=$(echo $KEY | jq '.data' | grep 'private_key_data' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^ *//;s/ *$//; s/ * / /g')
  #echo $BASE64

  #Convert/Generate CredFile Base64 String to Google Credentials File format
  echo $BASE64 | base64 --decode > ../response/cred-file-$SERVICEACCOUNT.json

  KEYID=$(cat ../response/cred-file-$SERVICEACCOUNT.json | grep 'private_key_id' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^ *//;s/ *$//; s/ * / /g')
  echo "Foi gerado a KeyID: $KEYID para a Service Account: $SERVICEACCOUNT@$PROJECT.iam.gserviceaccount.com"
}

request_gcp_info
vault_auth_role
generate_keys
