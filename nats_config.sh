#!/bin/bash
ansible_output=$(terraform output -json ip_address | jq -r '.[] | .[]') 
cat <<EOL > nats.conf 
# NATS Server Configuration 
# Listen for client connections. 
port: 4222 
log_file: "/var/log/nats-server.log" 
no_auth_user: testuser 
accounts: {     
    SYS: {         
        users: [             
            {user: admin, password: ILoveLinode2024}
	]
    } 
} 
system_account: SYS 
authorization: {
    users: [     
    {user: testuser, password: ILoveLinode}
    ]
} 
# Enable JetStream 
jetstream: true 
http_port: 8222 
websocket {   
  listen: "0.0.0.0:8888"   
  tls {     
    cert_file: "/etc/fullchain.pem"
    key_file: "/etc/privkey.pem"   
  } 
} 
# Routes for cluster communication 
cluster {
  listen: "0.0.0.0:6222"  

# Routes to other cluster nodes   
routes = [
EOL
# Process output 
echo "$ansible_output" | while IFS= read -r ip_address; do
    echo "\"nats://$ip_address:6222\"" >> nats.conf 
done
  # Add the closing brackets to new_nats.conf 
echo "]" >> nats.conf 
echo "}" >> nats.conf
