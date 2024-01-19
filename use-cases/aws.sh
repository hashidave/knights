#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200
unset VAULT_NAMESPACE




###################################################################################
###################################################################################
#######                   Postgres Dynamic Secret
vault read aws/creds/my-role

read -p $'\e[96mPress <Enter> to see audit data for aws creds'
echo -e "\e[33m-----------------------"

#### Examine the Audit Log for a Bit
grep "aws" ../vault-audit.log | tail -n 5 | jq