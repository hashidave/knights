#!/bin/bash
unset VAULT_TOKEN
unset VAULT_NAMESPACE
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_LICENSE_PATH=/etc/vault.d/license.hclic

rm $PWD/vault-audit.log

# start up a vault server
vault server -dev 


