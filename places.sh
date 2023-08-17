#!/bin/bash


#Ask Vault for a read-write password 
read  PGPASSWORD PGUSER <<< $(vault read -format=json database/creds/readwrite | jq -r '.data.password, .data.username')

echo "----------------------------+------------------------"
echo "Logon info:"
echo "PGUSER: $PGUSER"
echo "PGPASSWORD: $PGPASSWORD"
echo "----------------------------+------------------------"
echo
echo

echo "Interesting places report"
psql postgres  -c "Select * from places;"


echo "----------------------------+------------------------"
echo
echo
echo "Silly things report"
psql postgres -c "Select * from silly_things;"

echo "Press <Enter> to continue"
read X

echo "----------------------------+------------------------"
echo "Attempting write with read-write credentials. "
echo "----------------------------+------------------------"
echo
echo
psql postgres -c "insert into places (name, Relative_peril) values ('Swamp Castle', 'High. Sinking.')"

echo
echo
echo "----------------------------+------------------------"
echo "Contents of places after inserting Swamp Castle. "
echo "----------------------------+------------------------"

psql postgres  -c "Select * from places;"
