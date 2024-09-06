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
- The jumphost environment is based on Ubuntu 24.04 </br>
  - This can work with other distros, but may require tweaking of the local_exec functions in Terraform. </br>
- You will also need certificates for the front-end that can only be obtained via contacting Brian Apley, or by using the bastion provided during the workshops. </br>
  - Alternatively you can supply you own front-end to this and set up an Akamai property to serve the static pages and create the Global Traffic Manager </br>
- The bastion has the following packages installed: Curl, Git, JQ and Terraform </br>
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt install -qq -y gnupg software-properties-common curl git jq terraform
```
## Shell Setup 
The shell is preconfigured for you in the bastion environment. Certain environmental variables will be used throughout the Workshop, several are set at login via /etc/profile. All variables starting with TF_VAR are exposed to Terraform as variables that can be used in your scripts (sans TF_VAR), userid will be used to differentiate your files and instances for the workshop. me and me6 are your current IP Addresses to create firewalls for SSH within TF.
### Using The Shell
Navigate to the URL provided over HTTPS and you should get a login: prompt </br>
Once logged in you can right click for a menu, which includes a few noteworthy items: </br>
- Copy</br>
  - Copy copies items within the terminal to be used within the terminal</br>
- Paste</br>
  - Paste is used for items copied within the terminal</br>
- Paste from browser </br>
  - Paste from browser opens a dialogue box so you can paste in commands from other browser tabs, windows or elsewhere on your local system. </br>
  - For best results, paste 1 line per Paste from browser request</br>
- Black on White</br>
  - This will set your view of the terminal to a very bright and gaudy white screen with black text</br>
- White on Black</br>
  - Selecting this, will give you a classic terminal visual appeal</br>
- Monochrome </br>
  - Monochrome can be selected with either Black on white or White on black and will ensure just black and white shades. </br>
- Color Terminal </br>
  - Color Terminal can be selected with either Black on white or White on black and will give you linux color coded text. </br>

Outside of the menu, you can select text from within the terminal window and use your standard keyboard shortcut for Copy to add items to your local clipboard. </br>
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
- You will need an Akamai Connected Cloud account and a Personal Access Token </br>
- If you do not have a Personal Access Token, follow these instructions:
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
     ***SAVE THIS TOKEN SOMEWHERE SECURE - YOU CANNOT VIEW THIS AGAIN***
   - Click the blue button to acknowledge you have saved your PAT. </br>
   - Click back to the ***Linodes*** menu for later use.
- The Akamai lab environment includes the web front-end to this backend system. If you are supplying your own web-front end, you will need to incorporate the HTML files and create the path and query string routing for the Akamai Ion property.

## Repo Instructions
### Step 1 - Validate Prerequisites
If you do not already have a Linode Personal Access Token to be used in this exercise, create one now using the instructions above.

### Step 2 - Log In
Log in to the bastion using the URL and credentials at your seat.

### Step 3 - Per Participant Environment Set Up
Set a variable for your Linode Personal Access Token. This variable must be exported and follow the `TF_VAR_linode_token=` format. </br>
Terraform can access any environmental variable so long as it is exported and uses the `TF_VAR_` prefix </br>
Terraform will use these variables to build your instances and create your firewalls. </br>
`export TF_VAR_linode_token=tokeninformationhere` </br>
***Note: You MUST export the variable for it to be used with the terraform process!*** </br>
An alternate method is to place this in the `terraform.tfvars` file - but that would be really insecure. </br>
### Step 4 - Review and Select Regions
You should already be in the repo directory - but just make sure with `pwd` </br>
This should echo back /home/ followed by your login ID /edgenativeworkshop </br>
It should look like this:
`brent@localhost:/home/brent/edgenativeworkshop# pwd` </br>
`/home/brent/edgenativeworkshop` </br>
</br>
Now before starting the build process, decide on the regions to be used </br>
**You can get a current list of Akamai Connected Cloud regions by issuing the below curl command from the shell** </br>
```
curl -H "Authorization: Bearer $TF_VAR_linode_token" -H 'X-Filter: { "site_type" : "core" }' https://api.linode.com/v4/regions | jq .data[].id
```
Any of the resulting site IDs can be used to build your cluster. </br> 
To edit the regions issue the following command: </br>
`vi terraform.tfvars`
This will show you a list of strings, by default the following sites are used: San Francisco, Paris, Toronto and Osaka </br>
`regions       = ["us-west", "fr-par", "ca-central", "jp-osa"]` </br>
If you are good with the defaults, simply hit *`:`* and then *`q`* and then *`Enter`* on your keyboard to quit the file without saving </br>
***It is important to keep Osaka and the closest region to you in this list. If you want to add more, add more. If you want to reduce this to 2, reduce it to Osaka and the closest region to you. </br>
If you are not good with the defaults and want to edit this file, use the common vim commands: *`i`* puts you into insert mode. Then your keyboard will function like normal to edit the text (delete, type, etc...) </br>
When you are done editing, hit *`Esc`* on your keyboard, then *`:`* then *`x`* and finally *`Enter`* to save and exit</br>
***Note: that is a lower case x - case is important!*** </br>
### Step 5 - Review and Select Instances
You may also want to change your instance sizing. Current instances types can be pulled from the API with the following command: </br>
`curl https://api.linode.com/v4/linode/types | jq .data[].id` </br>
The default we will use in this exercise are the `g6-standard-2` These are shared instances with 1 vCPU and 2 GB of RAM. </br>
These should suffice for demonstration purposes, but are not suited for most production workloads. </br>
If you decide you want larger instances you can edit the `main.tf` file: </br>
`vi main.tf` </br>
In this file, you will find a block that looks like this: </br>
```
resource "linode_instance" "linode" {
  count       = length(var.regions)
  label       = "${var.userid}-${element(var.regions, count.index)}-${local.timestamp}"
  region      = element(var.regions, count.index)
  type        = "g6-standard-2"
  image       = "linode/ubuntu24.04"
  tags        = toset([var.userid])
  authorized_keys = [local.sanitized_ssh_key]
  stackscript_id = 1458080
}
```
Like before, using your editor, click *`i`* on your keyboard to enter insert mode, then arrow down to the `type` field and modify the `g6-standard-2` to fit your need </br>
As before, when you are done, hit *`Esc`* on the keyboard. Then *`:`*, followed by *`x`* and finally *`Enter`* - which will save the file and exit. </br>
**Some other key notations in this resource block are:** </br>
- The dynamically created `count` field.
  - The `length(var.regions)` statement creates a count of the number of regions listed in the `terraform.tfvars` file.
- The `label`
  - This creates a unique label on each instance using the imported system variable of TF_VAR_userid, which is set from whoami at logon, the region and a timestamp
- The `region` field
  - This dynamically sets a region using our regions variable in `terraform.tfvars`
- The `image` field sets which Linode Operating System image to use in this configuration
- The `tags` field
  - This too uses the TF_VAR_userid variable to apply a tag for logical grouping of the resources administratively
- The `authorized_keys` field
  - This field uses the data resource created above using the autocreated SSH keys that are populated at logon.
  - This will allow you to SSH to each node and validate functionality later
- The `stackscript_id` field
  - This field allows you to add an additional config script to each instance upon instatiation.
  - In this case, the script will set a hostname on the system equal to its City, install docker and get and install NATS

### Step 6 - Review Firewalls
Re-enter the main.tf file using `vi main.tf`
Arrow down to the resource block that looks like this:
```
resource "linode_firewall" "nats_firewall" {
  label = "${var.userid}-nats_workshop_firewall"

  inbound {
    label    = "allow-https"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443, 8888, 8443"
    ipv4     = local.cleaned_cidrs
    ipv6     = local.cleaned_ipv6_cidrs
    //ipv6     = ["::/0"]
  }
  inbound {
    label    = "allow-nats-nodes"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "6222"
    ipv4     = [for ip in linode_instance.linode : "${tolist(ip.ipv4)[0]}/32"]
  }
  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["${var.me}/32"]
    ipv6     = ["${var.me6}/128"]
  }
  inbound_policy = "DROP"
  outbound_policy = "ACCEPT"

  linodes = [for i in linode_instance.linode : i.id]
}
```
### Step 7 - Build Time
Thes rest of the build is a breeze and consists of only a few commands:
```
terraform init
terraform apply -target linode_instance.linode -auto-approve
terraform apply -auto-approve
terraform output all_ip_addresses
```
### Step 8 - Backend Testing and Validation

ssh in root@
docker container ls
ps -ef | grep nats
cat /root/nats.conf

### Step 9 - Akamaize It!
This will also produce a .tf file which is the GTM config. This will get loaded by the proctors </br>
The lab bastions have an Object Storage bucket mounted to /GTM where all the GTM Terraform files are output for integration by the Akamai admin. </br>

However, if you are building this in your own Akamai property, this is where you will get the Terraform configuration file for GTM

### Step 10 - Play the Game!
rm the .tf file BEFORE trying to destroy terraform



