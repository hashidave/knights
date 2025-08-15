#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200
unset VAULT_NAMESPACE



###################################################################################
###################################################################################
#######                   Authenticate to Vault using Approle 

# read in our approle.  It's not a secret so it can be stored in
# a local file
APP_ROLE=$(cat .app-role)

# Unwrap the token that was passed in from the orchestrator
#echo "Wrapped secret at app : $1"
APP_SECRET=`curl -s -S --header "X-Vault-Token: $1" --request POST http://127.0.0.1:8200/v1/sys/wrapping/unwrap | jq -r '.data.secret_id'`
#echo "APP_SECRET: $APP_SECRET"


# log on to vault & get our access token
read -r -d '' LOGIN_PAYLOAD<<-EOF 
{
    "role_id": "$APP_ROLE",
    "secret_id": "$APP_SECRET"
}
EOF
#echo "$LOGIN_PAYLOAD"
APP_TOKEN=`curl -s -S --data "$LOGIN_PAYLOAD" --request POST http://127.0.0.1:8200/v1/auth/approle/login | jq -r '.auth.client_token'`
echo "vault token:  $APP_TOKEN"
vault token lookup $APP_TOKEN

VAULT_TOKEN=$APP_TOKEN vault read secret/data/creds

VAULT_TOKEN=$APP_TOKEN vault read database/creds/pg_readonly
