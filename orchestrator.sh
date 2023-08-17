#!/bin/bash

# This script is the trusted controller the serves as our orchestrator
# In the real world this could be k8s, CI/CD, nomad, etc.  
# It presents a system-level identity that Vault can consume to then
# release approle secrets that are passed to the various applications

APP_SECRET=`vault write -wrap-ttl=60s -force -field=wrapping_token auth/approle/role/knights-ro/secret-id`
#echo "wrapped secret in controller: $APP_SECRET"

## kick off our app passing in the wrapped token
./knights-ro.sh $APP_SECRET

