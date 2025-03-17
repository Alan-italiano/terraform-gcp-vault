#!/bin/bash

##########################################################################################################################################################################################
##########################################################################################################################################################################################
##########################################################################################################################################################################################
################################################################ REVOKE EXISTING KEYS FOR GCP SERVICE ACCOUNT ############################################################################
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

revoke_key(){
  
  #Confirm Key Deletion
  KEYID=$(cat ../response/cred-file-target.json | grep 'private_key_id' | cut -d':' -f2 | sed 's/,.*//' | sed 's/"//g' | sed 's/^ *//;s/ *$//; s/ * / /g')
  
  echo "Confirma a exclusão da chave: $KEYID?"
  
  read -p "Digite S ou N: " CONFIRM

  if [ $CONFIRM = sim -o $CONFIRM = s -o $CONFIRM = Sim -o $CONFIRM = SIM -o $CONFIRM = S ]; then
    curl --insecure --header "X-Vault-Token: $TOKEN" --request POST --data '{"lease_id":"'$LEASEID'"}' $VAULT_ADDR/v1/sys/leases/revoke
    echo "A Chave $KEYID foi excluída com sucesso!"
  elif [ $CONFIRM = nao -o $CONFIRM = n -o $CONFIRM = Nao -o $CONFIRM = NAO -o $CONFIRM = N ]; then
    exit 1  
  else
    echo "Opção não válida!"
  fi

}

vault_auth
get_leaseid
revoke_key
