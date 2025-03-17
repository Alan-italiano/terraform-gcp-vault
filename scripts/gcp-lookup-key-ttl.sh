#!/bin/bash

##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
################################################################### LOOKUP TTL FOR EXISTING KEY ##########################################################################################
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
  #echo $TOKEN
  if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
    echo "Falha na autenticação do Vault!"
    exit 1
  fi
}

get_leaseid(){
  #Get LeaseID from gcp-generate-keys.json
  LEASEID=$(cat ../response/target-key.json | grep 'lease_id' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^*//g' | sed 's/ //g')
  #echo $LEASEID
}

revoke_key(){
  #Lookup key expiration
  KEYID=$(cat ../response/cred-file-target.json | grep 'private_key_id' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^ *//;s/ *$//; s/ * / /g')
  curl -s --insecure --header "X-Vault-Token: $TOKEN" --request POST --data '{"lease_id":"'$LEASEID'"}' $VAULT_ADDR/v1/sys/leases/lookup | jq '.' > ../response/lookup-ttl-key.json
  TTL=$(cat ../response/lookup-ttl-key.json | jq '.data' | grep 'ttl' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^*//g' | sed 's/ //g')
  HOURS=$(($TTL/3600))
  MINUTES=$((($TTL%3600)/60))
  SECONDS=$(($TTL%60))
  echo "O tempo de validade da chave: $KEYID é de $HOURS horas, $MINUTES minutos e $SECONDS segundos" 
} 

vault_auth
get_leaseid
revoke_key
