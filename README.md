# Akamai Edge Native Workshop
This workshop is meant to be enjoyed in person with your Akamai team. The shell environment is provided and has all the tooling you will need to complete the workshop along with some other automation.
For this workshop, you will login to the URL at your station, using the username and password also provided.

If you cannot use the web browser, you can use SSH or your own bastion that meets the below requirements.

## Repo Contents 
- you have found README :) Keep reading
- main.tf
  - This is where the magic happens. This files does the following:
- terraform.tfvars
  - This is the most important file outside of main.tf. It defines the regions where you will have cluster nodes. All other things depend on this.
- ipv4.txt & ipv6.txt
  - ipv4 and ipv6.txt are semi-static files. You can update them with values from https://techdocs.akamai.com/origin-ip-acl/docs/update-your-origin-server. These are just lists of Akamai edge IPs. They will be used to lock down the source addresses for https in the Cloud Firewalls
- nats_config.sh
  - nats_config.sh will be called locally by Terraform. Terraform will pass some IP addresses to nats_config to create the nats.conf that Terraform will then place on each node. This allows NATS to know who its neighbors are and communicate with them.
- static.txt
  - static.txt is the static part of the Akamai GTM Terraform configuration. Terraform will use a local exec to create a GTM Terraform file using TF outputs of region and ip address for each node deployed. This will get loaded to Akamai to distribute traffic among the nodes using an Akamai GTM property.

## Bastion Requirements
The jumphost environment is based on Ubuntu 24.04 </br>
This can work with other distros, but may require tweaking of the local_exec functions in Terraform. </br>
You will also need certificates for the front-end that can only be obtained via contacting Brian Apley, or by using the bastion provided during the workshops. Alternatively you can supply you own front-end to this and set up an Akamai property to serve the static pages and create the Global Traffic Manager </br>
The bastion has the following packages installed: Curl, Git, JQ and Terraform </br>

```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install -qq -y gnupg software-properties-common curl git jq terraform
```
## Shell Setup 
The shell is preconfigured for you in the bastion environment. Certain environmental variables will be used throughout the Workshop, several are set at login via /etc/profile. All variables starting with TF_VAR are exposed to Terraform as variables that can be used in your scripts (sans TF_VAR), userid will be used to differentiate your files and instances for the workshop. me and me6 are your current IP Addresses to create firewalls for SSH within TF.

### Variables automatically set in /etc/profile
```
export TF_VAR_userid=$(whoami)
export TF_VAR_me=$(curl -4 ifconfig.me)
export TF_VAR_me6=$(curl -6 ifconfig.me)
```
### Repo and SSH Key automated setup

SSH Keys and the Git environment are also set up for you upon login. You will be placed in the local copy of the repo each time you log in.
**Scripts from /etc/profile**
```
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
```
### Additional Requirements
You will need an Akamai Connected Cloud account and a Personal Access Token </br>
If you do not have a Personal Access Token, follow these instructions:
 - Navigate to https://cloud.linode.com
 - Log in to the portal using your Linode account - **OR** - If you have Akamai Connected Cloud in your Akamai contract, you can log in using your Akamai Control Center Account
 - One logged in, Click your user ID in the upper right.
   - Select API Tokens
 - Click the blue button for ***Create A Personal Access Token***
   - Give your token a label - maybe *Workshop*
   - In the *Expiry* dropdown, select ***In 1 month***
   - In the *Select All* line, Click the ***No Access*** selection
   - Then on the following lines, click the ***Read/Write*** selection
     - *Firewalls*
     - *IPs*
     - *Linodes*
   - And on the *Stackscripts* line, click ***Read Only***
   - Click the blue button at the bottom for ***Create Token*** </br>
     ***Note: If the button is greyed out, make sure you have selected an access level for all items.***
## Repo Instructions

## Additional Requirements
**Step 1**
  - If you do not already have a Linode Personal Access Token to be used in this exercise.
  - Log in to the bastion using the credentials at your seat:
  - 
Additionally you will need to set a variable for your Linode Personal Access Token. This variable must be exposed and follow the TF_VAR_linode_token= convention. 

export TF_VAR_linode_token=tokeninformationhere

An alternate method is to place this in the terraform.tfvars file - but that would be really insecure.

    
#Regions
curl -H "Authorization: Bearer $TF_VAR_linode_token" -H 'X-Filter: { "site_type" : "core" }' https://api.linode.com/v4/regions | jq .data[].id

Instances
curl https://api.linode.com/v4/linode/types | jq .data[].id

General Instructions
login
export TF_VAR_linode_token
terraform init
terraform apply -target linode_instance.linode -auto-approve
terraform apply-auto-approve
terraform output all_ip_addresses
ssh in root@
docker container ls
ps -ef | grep nats
cat /root/nats.conf

This will also produce a .tf file which is the GTM config. This will get loaded by the proctors
rm the .tf file BEFORE trying to destroy terraform



