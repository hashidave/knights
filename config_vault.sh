#!/bin/bash

# all the secrets in this file are garbage and are for example only.


vault audit enable file file_path=$PWD/vault-audit.log

# onboard a couple of static secrets
# kv is enabled at secret by default on non-HCP
 #vault secrets enable -version=2 -path=secret kv 

 vault kv metadata put -mount=secret -max-versions=5 -delete-version-after=30m creds
 vault kv put -mount=secret creds passcode=my-long-passcode number=8675309
 vault kv put -mount=secret team/audit passcode=Money$$ number=7654
 vault kv put -mount=secret team/eng passcode=GearHead number=3210
 vault kv put -mount=secret team/admin passcode=MyKidsNameHere number=2468


##########################################################################
# Set up the PKI Secrets Engine
vault secrets enable pki
vault secrets tune -max-lease-ttl=60m pki

# Generate a CSR for the intermediate Cert
vault write -field=csr pki/intermediate/generate/internal common_name="myvault.com Intermediate Authority" \
        ip_sans="127.0.0.1" ttl=60d > vault_int.csr

#sign the request with our fake root CA
openssl x509 -req -in vault_int.csr -CA ./knights_CA/rootCA.crt -CAkey ./knights_CA/rootCA.key \
        -CAcreateserial -out vault_int.crt -days 60 -sha256 -extfile ./knights_CA/knights_CA.conf 

#load the new cert into vault
vault write pki/intermediate/set-signed certificate=@vault_int.crt

# set up the CRL
# vault write pki/config/urls \
#    issuing_certificates="http://127.0.0.1:8200/v1/pki/ca" \
#    crl_distribution_points="http://127.0.0.1:8200/v1/pki/crl"

# now creatre a role to issue certs against
vault write pki/roles/knights.com \
    allowed_domains=knights.com \
    allow_subdomains=true \
    max_ttl=7m





##########################################################################
# initialize postgres engine
vault secrets enable database

USERNAME="vaultuser"
PW="SwampThing34"

vault write database/config/postgresql \
     plugin_name=postgresql-database-plugin \
     connection_url="postgresql://{{username}}:{{password}}@localhost:5432/postgres?sslmode=disable" \
     allowed_roles=pg_readonly,pg_readwrite\
     username=$USERNAME \
     password=$PW

# this would rotate the postgres root credential but my dev vault is ephemeral & my DB is not so
# I don't want to break it. :)
#vault write -force database/rotate-root/postgresql



# create roles
vault write database/roles/pg_readonly \
        db_name=postgresql \
        creation_statements=@readonly.sql \
        default_ttl=1h \
        max_ttl=24h


vault write database/roles/pg_readwrite \
        db_name=postgresql \
        creation_statements=@readwrite.sql \
        default_ttl=10m \
        max_ttl=1h

# user name template so we can tell where the user came from
vault write database/config/postgresql username_template="ACME-{{.RoleName}}-{{unix_time}}-{{random 8}}"

vault write sys/policies/password/example policy=@example_policy.hcl
vault write database/config/postgresql password_policy="example"




#############################################################
# enable Approle
vault auth enable approle
vault policy write knights-ro-app-policy ./knights-ro-app-policy.hcl

# create the role for knights-ro
# One-time use.  Can only be used from this system
vault write auth/approle/role/knights-ro \
  secret_id_num_uses=1 \
  secret_id_bound_cidrs="127.0.0.1/32" \
  secret_id_ttl=30m \
  token_policies="knights-ro-app-policy" \
  token_ttl=30m \
  token_max_ttl=30m \
  token_bound_cidrs="127.0.0.1/32"

vault read -field=role_id auth/approle/role/knights-ro/role-id > ./.app-role


# turn off hmac for stuff we want to see
vault secrets tune -audit-non-hmac-response-keys=created_time \
    -audit-non-hmac-response-keys=deletion_time -audit-non-hmac-response-keys=delete_version_after \
    -audit-non-hmac-response-keys=updated_time secret/


vault secrets tune -audit-non-hmac-response-keys=data  database/


#############################################################
#  RBAC

# Make some groups and policies for those groups
vault policy write team-eng -<<EOF
path "secret/data/team/eng" {
  capabilities = [ "create", "read", "update", "delete"]
}
EOF

vault write identity/group name="engineers" \
     policies="team-eng" \
     metadata=team="Engineering" \
     metadata=region="North America"
################################################
vault policy write team-admin -<<EOF
path "/" {
  capabilities = [ "create", "read", "update", "delete"]
}
EOF
 vault write identity/group name="admins" \
     policies="team-admin" \
     metadata=team="Admin Team" \
     metadata=region="North America"
################################################
vault policy write team-audit -<<EOF
path "/" {
  capabilities = [ "list"]
}
EOF
vault write identity/group name="auditors" \
     policies="team-audit" \
     metadata=team="Auditors" \
     metadata=region="North America"
################################################


## Make some users and tie them to entities
vault auth enable userpass

# grab the accessor
ACCESSOR=`vault auth list -format=json | jq -r '.["userpass/"].accessor'`

vault write auth/userpass/users/alice password="training" 
ENTITY=`vault write -field=id  identity/entity name="alice" \
     metadata=organization="ACME Inc." \
     metadata=team="Admins"` 
 
vault write identity/entity-alias name="alice" \
     canonical_id=$ENTITY \
     mount_accessor=$ACCESSOR 
     

vault write identity/group name="admins" \
       member_entity_ids=$ENTITY

######################################################
vault write auth/userpass/users/bob password="training" 
ENTITY=`vault write -field=id identity/entity name="bob" \
     metadata=organization="ACME Inc." \
     metadata=team="Engineering"`

vault write identity/entity-alias name="bob" \
     canonical_id=$ENTITY \
     mount_accessor=$ACCESSOR 

vault write identity/group name="engineers" \
       member_entity_ids=$ENTITY

####################################################     

vault write auth/userpass/users/chuck password="training"
ENTITY=`vault write -field=id  identity/entity name="chuck" \
     metadata=organization="ACME Inc." \
     metadata=team="Auditors"` 

vault write identity/entity-alias name="chuck" \
     canonical_id=$ENTITY \
     mount_accessor=$ACCESSOR 

vault write identity/group name="auditors" \
       member_entity_ids=$ENTITY
 


##########################################################################
##########################################################################
##########################################################################
# initialize aws engine
vault secrets enable -path=aws aws

vault write aws/config/root \
    access_key=$AWS_ACCESS_KEY_ID \
    secret_key=$AWS_SECRET_ACCESS_KEY \
    region=us-east-1

# NOTE:  Vault supports rotating the secret key.


# Credentials vended by Vault will have the policy attached here
vault write aws/roles/my-role \
        credential_type=iam_user \
        policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1426528957000",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

##########################################################################
##########################################################################
##########################################################################
# initialize Transit
vault secrets enable -path=transit transit

vault write -f transit/keys/my-key