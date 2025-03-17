#!/bin/bash

##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
################################################################# RENEW EXISTING KEYS FOR GCP SERVICE ACCOUNT ############################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################

vault_auth(){
  CONFIG_FILE="../.vault_credentials"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Arquivo de configuração '$CONFIG_FILE' não encontrado!"
    exit 1
  fi

  source "$CONFIG_FILE"
  #Vault Authentication - Approle
  TOKEN=$(curl -s --insecure --request POST --data '{"role_id":"'$ROLE_ID'","secret_id":"'$SECRET_ID'"}' $VAULT_ADDR/v1/auth/approle/login | jq '.auth' | grep 'client_token' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^*//g')
  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Falha na autenticação do Vault!"
    exit 1
  fi

}

get_leaseid(){
  #Get LeaseID from gcp-generate-keys.json
  LEASEID=$(cat ../response/target-key.json | grep 'lease_id' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^*//g' | sed 's/ //g')
}

request_increase_time(){
  #Request Incremental Lease Time Info
  KEYID=$(cat ../response/cred-file-target.json | grep 'private_key_id' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^ *//;s/ *$//; s/ * / /g') 
  echo "Informe o tempo adicional que a chave: $KEYID permanecerá ativa"
  read -p "Digite o valor em dias, minutos ou horas, exemplo 1d(dia), 1m(minuto), 1h(hora): " LEASETIME
}

renew_key(){
  #Renew with its Leaseid
  curl -s --insecure --header "X-Vault-Token: $TOKEN" --request POST --data '{"lease_id":"'$LEASEID'","increment":"'$LEASETIME'"}' $VAULT_ADDR/v1/sys/leases/renew | jq '.' > ../response/renew-key.json
}

vault_auth
get_leaseid
request_increase_time
renew_key
