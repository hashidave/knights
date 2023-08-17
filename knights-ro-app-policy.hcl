# defines what our app can access
path "database/creds/pg_readonly" {
  capabilities = [ "read" ]
}

path "sys/leases/lookup/database/creds/pg_readonly"{
 capabilities= [ "list", "read", "update", "sudo" ] 
}


path "secret/metadata/creds" {
  capabilities = ["read"]
}
path "secret/data/creds" {
  capabilities = ["create", "update", "read"]
}

path "pki/issue/knights.com" {
  capabilities = ["create", "update"]
}


path "pki/revoke" {
  capabilities = ["sudo", "create", "update"]
}