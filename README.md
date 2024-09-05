# workshop-tf
This workshop is meant to be enjoyed in person with your Akamai team. The shell environment is provided and has all the tooling you will need to complete the workshop along with some other automation.
For this workshop, you will login to the URL at your station, using the username and password also provided.

If you cannot use the web browser, you can use SSH or your own Jumphost.

#Requirements
The jumphost environment is based on Ubuntu 24.04
  --can work with other distros but may require tweaking of the local_exec functions
  
#Packages Required
The jump host has the following packages installed
sudo apt-get install -y gnupg software-properties-common curl git jq
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install -y terraform

#Environment Variables
Certain environmental variables will be used throughout the Workshop, several are set at login via /etc/profile. All variables starting with TF_VAR are exposed to Terraform as variables that can be used in your scripts (sans TF_VAR), userid will be used to differentiate your files and instances for the workshop. me and me6 are your current IP Addresses to create firewalls for SSH within TF.

.../etc/profile
export TF_VAR_userid=$(whoami)
export TF_VAR_me=$(curl -4 ifconfig.me)
export TF_VAR_me6=$(curl -6 ifconfig.me)

SSH Keys and the Git environment are also set up for you upon login.
  if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
	  mkdir -p "$HOME/.ssh"
	  ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" -q
  fi
  # Check if .git directory exists in $HOME 
  if [ ! -d "$HOME/.git" ]; then
   	  echo ".git directory not found, initializing git repository..."
   	  git init "$HOME" 
  fi
      	# Check if the edgenativeworkshop repo is already cloned 
  if [ ! -d "$HOME/edgenativeworkshop/.git" ]; then     
	  echo "Cloning edgenativeworkshop repository..."
   	  git clone https://github.com/akamai/edgenativeworkshop.git "$HOME/edgenativeworkshop" 
  else     
	  echo "edgenativeworkshop repository already present." 
  fi
  cd $HOME/edgenativeworkshop

Manual entry variables
export TF_VAR_linode_token=tokeninformationhere
Good thing is there is ONLY one variable to set. You can place this in the terraform.tfvars file - but that would be really insecure.

#The repo files - 
--you have found README :) Keep reading
--main.tf - this is where the magic happens. This files does the following:
  --terraform.tfvars
    This is the most important file outside of main.tf. It defines the regions where you will have cluster nodes. All other things depend on this.
    
  --ipv4.txt
  --ipv6.txt
    ipv4 and ipv6.txt are semi-static files. you can update them with values from https://techdocs.akamai.com/origin-ip-acl/docs/update-your-origin-server. These are just lists of Akamai edge IPs. They will be used to lock down the source addresses for https in the Cloud Firewalls
  --nats_config.sh
    nats_config.sh will be called locally by Terraform. Terraform will pass some IP addresses to nats_config to create the nats.conf that Terraform will then place on each node. This allows NATS to know who its neighbors are and communicate with.
  --static.txt
    static.txt is the static parts of the Akamai GTM Terraform configuration. Terraform will use a local exec to create a GTM Terraform file using TF outputs of region and ip address. This will get loaded to Akamai to distribute traffic among the nodes.
    
#Regions
curl -H "Authorization: Bearer $TF_VAR_linode_token" -H 'X-Filter: { "site_type" : "core" }' https://api.linode.com/v4/regions | jq .data[].id

Instances
curl https://api.linode.com/v4/linode/types | jq .data[].id



