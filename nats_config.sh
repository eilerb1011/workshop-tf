#!/bin/bash
ansible_output=$(terraform output -json ip_address | jq -r '.[] | .[]') 
# Create or truncate routes.txt 
> routes.txt  
# Process output 
echo "$ansible_output" | while IFS= read -r ip_address; do
    echo "\"nats://$ip_address:6222\"" >> routes.txt 
done
cat nats.conf routes.txt > new_nats.conf  
  # Add the closing brackets to new_nats.conf 
echo "]" >> new_nats.conf 
echo "}" >> new_nats.conf
