#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200
unset VAULT_NAMESPACE

APP_TOKEN=$VAULT_TOKEN


###################################################################################
###################################################################################
#######                   Postgres Dynamic Secret

# Now we can get some dynamic creds for postgres
 read  PGPASSWORD PGUSER LEASE_ID_WHOLE <<< $(curl -S -s --header "X-Vault-Token: $APP_TOKEN" \
       http://127.0.0.1:8200/v1/database/creds/pg_readonly \
       | jq -r '[.data.password,  .data.username, .lease_id] | join (" ")' )

#@curl -S -s --header "X-Vault-Token: $APP_TOKEN" \
#      http://127.0.0.1:8200/v1/database/creds/pg_readonly |
      
      
    #   \
    #   | jq -r '[.data.password,  .data.username, .lease_id] | join (" ")'



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
grep "database" ../vault-audit.log | tail -n 5 | jq



