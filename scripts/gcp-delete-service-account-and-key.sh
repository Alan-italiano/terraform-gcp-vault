#!/bin/bash

##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
##################################################################### REMOVE ROLESET GCP SERVICE ACCOUNT #################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################

#GCP Project-ID
PROJECT='psyched-silicon-405818'

vault_auth(){
  #Loading environment variables for Vault Auth
  CONFIG_FILE="../.vault_credentials"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Arquivo de configuração '$CONFIG_FILE' não encontrado!"
    exit 1
  fi

  source "$CONFIG_FILE"

  #Vault Authentication - Approle
  TOKEN=$(curl --insecure --request POST --data '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' $VAULT_ADDR/v1/auth/approle/login | jq '.auth' | grep 'client_token' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^*//g')
  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Falha na autenticação do Vault!"
    exit 1
  fi
}

revoke_key(){
  #Remove Roleset Service Account
  curl -s --insecure --header "X-Vault-Token: $TOKEN" --request DELETE $VAULT_ADDR/v1/gcp/roleset/$PROJECT
}

vault_auth
revoke_key
