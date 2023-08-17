#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200

#Ask Vault for a read-only password 
read  PGPASSWORD PGUSER <<< $(vault read -format=json database/creds/readonly | jq -r '[.data.password,  .data.username
] | join (" ")' )

echo "----------------------------+------------------------"
echo "Logon info:"
echo "PGUSER: $PGUSER"
echo "PGPASSWORD: $PGPASSWORD"
echo "----------------------------+------------------------"
echo
echo

echo "127.0.0.1:5432:postgres:$PGUSER:$PGPASSWORD" > ~/.pgpass

psql -h 127.0.0.1 -U $PGUSER postgres  -c "Select * from knights;"

echo "----------------------------+------------------------"
echo "Attempting write with read-only credentials. "
echo "(prepare for spectacular failure....)"
echo "----------------------------+------------------------"
echo
echo
echo "Press <ENTER> to continue"
read x
psql -h 127.0.0.1 -U $PGUSER postgres -c "insert into knights (name, Relative_peril) values ('European Swallow', 'not event a knight')"
