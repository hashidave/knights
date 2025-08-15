#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200
unset VAULT_NAMESPACE
PLAINTEXT="1234-5678-9101-1121"

echo "Encrypting plaintext with FPE: $PLAINTEXT"
echo -e "\e[33m-----------------------"
ENCODED_OUTPUT=$(vault write transform/encode/payments \
     value=$PLAINTEXT \
     -format=json | jq -r '.data | .encoded_value') \
     && echo encoded_value: $ENCODED_OUTPUT


echo -e "\e[33m-----------------------"
echo "decrypt using 'vault write transform/decode/payments value=$ENCODED_OUTPUT"

