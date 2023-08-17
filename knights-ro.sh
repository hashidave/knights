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


# ----- Debugging stuff
echo "APP_TOKEN: $APP_TOKEN"
# vault token lookup $APP_TOKEN
# echo "-----"
# POLICIES=$(vault token lookup --format=json $APP_TOKEN | jq -r '.data.policies[1]')
# echo "POLICIES: $POLICIES"
# vault policy read $POLICIES

# echo "requesting dynamic postgres secret"
# curl --header "X-Vault-Token: $APP_TOKEN" \
#       http://127.0.0.1:8200/v1/database/creds/pg_readonly



###################################################################################
###################################################################################
#######                   Postgres Dynamic Secret

# Now we can get some dynamic creds for postgres
read  PGPASSWORD PGUSER LEASE_ID_WHOLE <<< $(curl -S -s --header "X-Vault-Token: $APP_TOKEN" \
      http://127.0.0.1:8200/v1/database/creds/pg_readonly \
      | jq -r '[.data.password,  .data.username, .lease_id] | join (" ")' )

echo "----------------------------------------------------"
echo "Logon info:"
echo "PGUSER: $PGUSER"
echo "PGPASSWORD: $PGPASSWORD"
echo "----------------------------------------------------"
echo
echo

read -p $'\e[96mPress <Enter> to query database>\e[0m]'

export PGPASSWORD
export PGUSER
psql -h 127.0.0.1 postgres  -c "Select * from knights;"


read -p $'\e[96mPress <Enter> to see active leases'
echo -e "\e[33m-----------------------"
echo -e "\e[33m----- All current Leases --------"

#vault list sys/leases/lookup/database/creds/pg_readonly
curl -S -s --header "X-Vault-Token: $APP_TOKEN" --request LIST http://127.0.0.1:8200/v1/sys/leases/lookup/database/creds/pg_readonly \
    | jq | jq -r '.data.keys'
echo -e "\e[33m-----------------------"

read -p $'\e[96mPress <Enter> to see current lease details'

IFS="/"
read -a LEASE_PARTS <<<"$LEASE_ID_WHOLE"
INDEX=${#LEASE_PARTS[*]}
LEASE_ID=${LEASE_PARTS[$(($INDEX-1))]}
echo "LEASE_ID : $LEASE_ID"
#vault lease lookup database/creds/pg_readonly/$LEASE_ID
read -r -d '' PAYLOAD<<-EOF 
{
    "lease_id": "$LEASE_ID_WHOLE"
}
EOF

curl -S -s --header "X-Vault-Token: $APP_TOKEN" --request POST --data "$PAYLOAD" \
     http://127.0.0.1:8200/v1/sys/leases/lookup | jq
    #| jq | jq -r '.data.keys'

read -p $'\e[96mPress <Enter> to see audit data for database secrets'
echo -e "\e[33m-----------------------"


#### Examine the Audit Log for a Bit
grep "database" vault-audit.log | tail -n 1 | jq






###################################################################################
###################################################################################
#######                   Static Secret Management
 echo -e "\e[33m-----------------------"
 read -p $'\e[96mPress <Enter> to see static secret "creds"'

echo -e "\e[33m-----------------------"
echo "    Static Secrets   "
echo -e "\e[33m-----------------------"
curl -S -s --header "X-Vault-Token: $APP_TOKEN"  \
     http://127.0.0.1:8200/v1/secret/data/creds | jq



# #vault kv metadata get -mount=secret creds
# curl -S -s --header "X-Vault-Token: $APP_TOKEN" http://127.0.0.1:8200/v1/secret/metadata/creds | jq

read -p $'\e[96mPress <Enter> to createa a new static secret version of "creds"'
echo -e "\e[33m-----------------------"
#Store a new secret version
#vault kv put -mount=secret -field=version creds passcode=N0tS3cure number=Transylvania-6-5000
read -r -d '' PAYLOAD<<-EOF 
{
  "data": {
    "passcode=": "N0tS3cure",
    "number": "Transylvania-6-5000"
  }
}
EOF

curl -S -s --header "X-Vault-Token: $APP_TOKEN" -X PUT --data "$PAYLOAD" \
     http://127.0.0.1:8200/v1/secret/data/creds | jq



# # rotate the static secret
# read -p $'\e[96mPress <Enter> to rotate "creds"'
# echo -e "\e[33m-----------------------"
# #vault read -format=json sys/policies/password/example/generate 
# NEW_SECRET=$(curl -S -s --header "X-Vault-Token: $APP_TOKEN" \
#     http://127.0.0.1:8200/v1/sys/policies/password/example/generate | jq)

# TODO:  Set the new secret    

# read -p $'\e[96mPress <Enter> to update "creds"'
# echo -e "\e[33m-----------------------"

# #vault kv put -mount=secret  creds passcode=$(vault read -field=password sys/policies/password/example/generate) number=1800-flowers
# read -r -d '' PAYLOAD<<-EOF 
# {
#   "data": {
#     "passcode=": "N0tS3cure",
#     "number": "Transylvania-6-5000"
#   }
# }
# EOF

# curl -S -s --header "X-Vault-Token: $APP_TOKEN" -X PUT --data "$PAYLOAD"  \
#     http://127.0.0.1:8200/v1/secret/data/creds | jq



read -p $'\e[96mPress <Enter> to read "creds"'
echo -e "\e[33m-----------------------"
curl -S -s --header "X-Vault-Token: $APP_TOKEN"  \
     http://127.0.0.1:8200/v1/secret/data/creds | jq


read -p $'\e[96mPress <Enter> to see metatdata for "creds"'
echo -e "\e[33m-----------------------"

# check the metadata now
#vault kv metadata get -mount=secret creds
curl -S -s --header "X-Vault-Token: $APP_TOKEN" http://127.0.0.1:8200/v1/secret/metadata/creds | jq



read -p $'\e[96mPress <Enter> to see audit data for "creds"'
echo -e "\e[33m-----------------------"
#### Examine the Audit Log for a Bit
grep "creds" vault-audit.log | tail -n 1 | jq




###################################################################################
###################################################################################
#######                   PKI

read -p $'\e[96mPress <Enter> to request a certificate for knights.com'
echo -e "\e[33m-----------------------"
#vault write pki/issue/knights.com common_name=www.knights.com
read -r -d '' PAYLOAD<<-EOF 
{
    "common_name": "www.knights.com",
    "ttl": "7m"
}
EOF

CERTINFO=$(curl -S -s --header "X-Vault-Token: $APP_TOKEN" --request POST --data "$PAYLOAD"  \
    http://127.0.0.1:8200/v1/pki/issue/knights.com) 
echo -e "\e[33m-----------------------"
echo $CERTINFO | jq

echo -e "\e[33m-----------------------"

read -p $'\e[96mPress <Enter> to revoke the certificate for knights.com'
echo -e "\e[33m-----------------------"

read SERIAL_NUMBER <<< $(echo $CERTINFO | jq -r '.data.serial_number')
echo "Revoking Cert w/ Serial # : $SERIAL_NUMBER"

read -r -d '' PAYLOAD<<-EOF 
{
  "serial_number": "$SERIAL_NUMBER"
}
EOF
curl -S -s --header "X-Vault-Token: $APP_TOKEN" --request POST --data "$PAYLOAD" \
    http://127.0.0.1:8200/v1/pki/revoke | jq