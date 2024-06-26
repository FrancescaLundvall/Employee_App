

##scripts

##Start vault and initialize the database secrets engine
##Vault -dev is not meant for use in production
##This dev-mode server requires no further setup 
##Local vault CLI will be authenticated to talk to it
##It is insecure and will lose data on every restart (since it stores data in-memory). 
##It is only made for development or experimentation.
## It requires only one unseal key. T
##his is much less secure than production, 
##which requires 3 of 5 unseal keys to unseal the vault
vault server -dev

##In a linux terminal do all of the following

cd HashicorpDemo
cd Employee_App

##Export env vars
export VAULT_ADDR=http://127.0.0.1:8200

export VAULT_TOKEN=


vault secrets enable database

##Create postgres connection
##The method scram-sha-256 performs password authentication.
## It is a challenge-response scheme that prevents password sniffing and
## supports storing passwords in a cryptographically secure way
vault write database/config/my-postgresql-database \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="admin-role, read-only" \
    connection_url="postgresql://{{username}}:{{password}}@localhost:5432/HashiCorpDemo" \
    username="postgres" \
    password="postgres" \
    password_authentication="scram-sha-256"


##Create roles
vault write database/roles/admin-role \
    db_name="my-postgresql-database" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT,INSERT,DELETE,UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

vault write database/roles/read-only \
    db_name="my-postgresql-database" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\"; GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"


##Create a policy definition file, db_creds.hcl.
##This policy allows read operation on the database/creds/readonly 
##path to obtain the dynamically generated
## username and password to access the PostgreSQL database.
##In addition, the policy allows renewal of the lease if necessary.
tee db_creds.hcl <<EOF
path "database/creds/read-only" {
  capabilities = [ "read" ]
}

path "database/creds/admin-role" {
  capabilities = [ "read" ]
}

path "sys/leases/renew" {
  capabilities = [ "update" ]
}
EOF

vault policy write db_creds db_creds.hcl


##Generate credentials
vault read database/creds/admin-role
vault read database/creds/read-only

##Using vault lease commands
vault lease lookup 
vault lease renew
vault lease revoke
#prove revokation: rerun 
vault lease lookup


#Create a token with db_creds policy attached and save it as an environment variable.
DB_TOKEN=$(vault token create -policy="db_creds" -format json | jq -r '.auth | .client_token')

##Execute the consul-template command to populate config.yml file.
##This allows the application to check the
## most up to date creds without having to generate new ones each time
VAULT_TOKEN=$DB_TOKEN consul-template \
        -template="config.yml.tpl:config.yml" -once
