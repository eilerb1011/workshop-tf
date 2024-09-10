# Akamai Edge Native Workshop
This workshop is meant to be enjoyed in person with your Akamai team. The shell environment is provided and has all the tooling you will need to complete the workshop along with some other automation.
For this workshop, you will login to the URL at your station, using the username and password that will also be provided. In this workshop you will build a full environment of Akamai caching, Global Traffic Management, Edge functions, Cloud Computing and Object Storage using Terraform to run a Node base application with a backend leveraging NATS to extend an existing data platform to a global audience.

## TLDR; ##
- Log in to the bastion
- `export TF_VAR_linode_token=yourlinodetokenthatyourcreatedwithappropriatepermissions`
- `terraform init`
- `terraform apply -target linode_instance.linode -auto-approve`
- `terraform apply -auto-approve`
- Play the game @ *https://workshop.connected-cloud.io/scoreboard/testscore.html?origin=edgenative*
  - You can swap out `edgenative` in the query string for the userid you used to log in to the bastion
- `terraform destroy -auto-approve`
  
## Workshop Scenario
You are a Financial Services company based in Tokyo and have a trading platform for securities on the Tokyo exhange. You are hosting your backend in Dynamo and have recently started getting requests for several large clients in the USA and Europe. After reviewing your architecture, you realize the performance will not be conducive to serving users abroad from the AWS Japan region. It will also be far too expensive to expand your Dynamo back-end to use Global Tables, additional DAX and regional API Gateways. So you have set out to create an alternate architecture that will leverage your existing investments and still provide high performance globally while keeping costs under control.  </br>

In the exercise, you will build the edge-native, distributed application that runs an Options Trading platform described here - *https://github.com/ccie7599/edge-trader*. </br>
</br>
The exercise demonstrates a use case of running both stateless/stateful services and applications, across distributed ephemeral nodes, with the source-of-truth for the game similarly distributed across each node. </br>
By embracing edge-native concepts, this exercise features the following benefits: </br>
- Performance - since application and NATS.io nodes can be deployed anywhere, we are using Akamai Connected Cloud as our infrastructure, with single-digit millisecond latency to the CDN front-door of the application. </br>
- Scale - game nodes can be horizontially scaled, and will automatically converge around node changes and node adds/deletes. </br>
- Reliability - each node has a 99.9% base uptime SLA, and the game can withstand multiple node failures while still maintaining uptime. </br>
- Security - all user-facing services are accessed through Akamai's security layer, and ohter security features protect the infrastructure. </br>

## Repo Contents 
- you have found README :) Keep reading
- main.tf
  - This is where the magic happens. This files does the following: </br>
    - Creates the cloud instances
    - Creates the firewalls based upon the Cloud instances built and IP Addresses listed for the instances, your bastion and the files defining the Akamai ranges.
    - Copies your SSH keys to each instance as well as a certificate to secure communications to the Akamai network.
    - Uses a local exec provisioner to initiates the NATS configuration based on the output on the Cloud instances and copies it to each node.
    - Starts NATS and all associated Docker containers on each node.
    - Creates your userid in sudo group on each node, and associates it with your SSH key, then disables root SSH login after all configuration has been done using the remote exec provisioner.
    - Creates a GTM file based upon the output of the Cloud instances.
- terraform.tfvars
  - This is the most important file outside of main.tf. It defines the regions where you will have cluster nodes. All other things depend on this.
- ipv4.txt & ipv6.txt
  - ipv4 and ipv6.txt are semi-static files. You can update them with values from https://techdocs.akamai.com/origin-ip-acl/docs/update-your-origin-server. These are just lists of Akamai edge IPs. They will be used to lock down the source addresses for https in the Cloud Firewalls
- nats_config.sh
  - nats_config.sh will be called locally by Terraform. Terraform will pass some IP addresses to nats_config to create the nats.conf that Terraform will then place on each node. This allows NATS to know who its neighbors are and communicate with them.
- static.txt
  - static.txt is the static part of the Akamai GTM Terraform configuration. Terraform will use a local exec to create a GTM Terraform file using TF outputs of region and ip address for each node deployed. This will get loaded to Akamai to distribute traffic among the nodes using an Akamai GTM property.

## Bastion Requirements
- If you cannot use the web browser, you can use SSH or your own bastion that meets the below requirements. </br>
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
export TF_VAR_sudo=$(whoami)-adminpass
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
  if [ ! -d "$HOME/workshop/.git" ]; then     
	  echo "Cloning workshop repository..."
   	  git clone https://github.com/eilerb1011/workshop-tf "$HOME/workshop" 
  else     
	  echo "workshop repository already present." 
  fi
  cd $HOME/workshop
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
   - And on the following lines, click ***Read Only***
     - *Events*
     - *Stackscripts*
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
Re-enter the `main.tf` file using `vi main.tf`
Arrow down to the resource block that looks like this: </br>
This is the linode_firewall instance which creates a firewall policy for your new instances. The Terraform resource name is nats_firewall. However the label applied in the Akamai Connected Cloud portal and API will reflect your userid-nats_workshop_firewall. This policy applies to all our instances, and this is done using the `linodes = [..]` at the bottom of the resource block. This statement loops through all linodes and pulls their Linode IDs to add them to the policy. This policy has a default of drop inbound traffic unless specified (or established) and allow outbound traffic. </br>
There are 3 inbound rules defined: </br>
  - `allow-https` allows all the ports and protocols used between the Akamai Edge and the hosts.</br>
    - The `ipv4` and `ipv6` keys are to define souce addresses or subnets</br>
    - In this case, we are reading in the `ipv4.txt` and `ipv6.txt` in the repo, and reformatting them for insertion here as a local variable (this is done above the `linode_instance` resource block if you want to look at it).</br>
  - `allow-nats-nodes` allows the traffic between hosts, so that only our nats hosts can talk to each other on the nats port.</br>
    - This uses a dynamic list created from the ipv4 address of each instantiated hosts /32 public address </br>
  - `allow-ssh` </br>
    - We do not want anybody else accessing these hosts. So SSH is locked down to only be accessible from the public IP of the machine used to execute the Terraform configuration. This uses our system variables set at logon time for our current IPv4 and IPv6 addresses</br>
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
`terraform init` </br>
And </br>
`terraform apply -target linode_instance.linode -auto-approve` </br>

You should receive the message below when issuing the apply command. This is nothing to be concerned about. </br>
This message results from the -target flag. This is used because the number of instances is dynamic but drives some other factors in the local and remote execs. So the linode_instance.linode resource must be fully executed before others can be planned. This is also why running without the target flag initially will produce an error.
```
╷
│ Warning: Resource targeting is in effect
│
│ You are creating a plan with the -target option, which means that the result of this plan may not represent all of the changes requested by the current configuration.
│
│ The -target option is not for routine use, and is provided only for exceptional situations such as recovering from errors or mistakes, or when Terraform specifically suggests to use it as part of
│ an error message.
╵
╷
│ Warning: Applied changes may be incomplete
│
│ The plan was created with the -target option in effect, so some changes requested in the configuration may have been ignored and the output values may not be fully updated. Run the following
│ command to verify that no other changes are pending:
│     terraform plan
│
│ Note that the -target option is not suitable for routine use, and is provided only for exceptional situations such as recovering from errors or mistakes, or when Terraform specifically suggests
│ to use it as part of an error message.
╵
```
Then you can finish the installation by issuing the following command: </br>
`terraform apply -auto-approve` </br>
If you issue the command too quickly, you may receive some failures due to docker not being fully ready to go from the initial stackscript load. This can be resolved by simply waiting a minute before running the `terraform apply` command. Or just running the command a second time.

Once successful, you should see an Apply complete message along with some outputs:
```
Apply complete! Resources: 2 added, 4 changed, 2 destroyed.                                                                                                                                           
                                                                                                                                                                                                      
Outputs:                                                                                                                                                                                              
                                                                                                                                                                                                      
all_ip_addresses = [ 
]
```
### Step 8 - Backend Testing and Validation
In this next step, you can use the Terraform Outputs (that should be on your screen) to validate the following in each node: </br>
  - There is a valid `nats.conf` on the system with routes to other nodes.</br>
  - The nats process is running with an appropriate hostname and config.</br>
  - The application Docker containers are running </br>
  - In Osaka only, you can validate the read in of the external stream and post to the NATS cluster </br>
If you have inadvertantly cleared your screen, you can get the IP Addresses of your instances with `terraform output all_ip_addresses` </br>
From you shell, ssh into each node. Each node already has your SSH keys on it from the Terraform build. </br>
`ssh @1.2.3.4` where you replace `1.2.3.4` with on of the IP addresses output from Terraform. </br>
Next issue: `sudo cat /root/nats.conf` </br>
Your sudo password is your username with `-adminpass` appended. So an example would be, for user1, the sudo password will be `user1-adminpass`</br>
This should return a config file with a routes sectoin at the bottom containing the IP addresses from the Terraform output. </br>
```
# Routes to other cluster nodes                                                                                                                                                                       
routes = [                                                                                                                                                                                            
"nats://45.33.110.50:6222"                                                                                                                                                                            
"nats://172.232.55.213:6222"                                                                                                                                                                          
"nats://172.105.15.165:6222"                                                                                                                                                                          
"nats://172.233.66.139:6222"                                                                                                                                                                          
]
```
Next, validate NATS is running and has a hostname defined mathcing the node hostname.</br>
`sudo ps -ef | grep nats` </br>
This should return a running process that looks like this: </br>
```root        5980       1  0 21:29 pts/0    00:00:00 nats-server -c /root/nats.conf --cluster_name nats_global --name Osaka```</br>
Then validate you have 2 -3 containers running, depending on the region. In Osaka, you will have 3. Everywhere else, you should have 2. </br>
`sudo docker container ls` </br>
The output should look similar to this: </br>
```
CONTAINER ID   IMAGE                    COMMAND                  CREATED          STATUS                    PORTS                                             NAMES                                   
01ba535f3b7f   brianapley/redis-nats    "docker-entrypoint.s…"   53 minutes ago   Up 53 minutes                                                               connector                               
4182ad8b3739   brianapley/node-http     "docker-entrypoint.s…"   54 minutes ago   Up 54 minutes             0.0.0.0:8443->8443/tcp, :::8443->8443/tcp         node-http                               
7987b840f052   brianapley/edge-trader   "./entrypoint.sh"        54 minutes ago   Up 54 minutes (healthy)   0.0.0.0:443->443/tcp, :::443->443/tcp, 1880/tcp   edge-trader
```
Last, since this is the output from the Osaka node, view the logs from the `redis-nats` container with `sudo docker container logs connector` </br>
This should produce an output like this: </br>
```
Received message: {                                                                                                                                                                                   
  id: '1725658723785-0',                                                                                                                                                                              
  message: [Object: null prototype] { price: '209.99' }                                                                                                                                               
}                                                                                                                                                                                                     
Published message to NATS on subject "redisprice2"                                                                                                                                                    
Received message: {                                                                                                                                                                                   
  id: '1725658724787-0',                                                                                                                                                                              
  message: [Object: null prototype] { price: '211.26' }                                                                                                                                               
}                                                                                                                                                                                                     
Published message to NATS on subject "redisprice2"                                                                                                                                                    
Received message: {                                                                                                                                                                                   
  id: '1725658725789-0',                                                                                                                                                                              
  message: [Object: null prototype] { price: '209.25' }                                                                                                                                               
}                                                                                                                                                                                                     
Published message to NATS on subject "redisprice2"
```
And this shows that the system is taking in messages from the external stream and publishing them to the global NATS cluster. </br>

### Step 9 - Akamaize It!
**Global Traffic Management**
A Terraform file is also generated in the previous step of the workshop. It is created with your userid followed by `.tf` and is placed in the `/gtm-data` folder. It will be applied to an Akamai Demo config on your behalf. The file will generate a GTM property under the connectedcloud5.akadns.net domain, with the property name equal to your userid, and a GTM DNS name equal to your userid followed by *.connectedcloud5.akadns.net*. This name will performance load balance each request, mapping users to the most proximate Compute region with no bias for load distribution. </br>

There are two default regions pre-built-</br>
*edgenative.connectedcloud5.akadns.net* - uses all four of the workshop regions for distribution - the regions in your `terraform.tfvars` file.
legacy.connectedcloud5.akadns.net - uses only one region to simulate a legacy, centralized origin. </br>

**Akamai Ion and WAF** </br>
The workshop Akamaized URL is workshop.connected-cloud.io. For the API, Websocket, and Server-Sent Events components of the application, using the origin={username} query string will instruct Ion to use *{username}.connectedcloud5.akadns.net* as an origin. The HTML components of the application are stored in Object Storage. The can be found in the repo here: *https://github.com/ccie7599/edge-trader*</br>

**Akamai EdgeWorkers** </br>
The Get Quote service within the application uses Akamai EdgeWorkers to execute server-side javascript that calculates option value based on strike price and current price. The Edgeworker request is in the format of `/quote?currentPrice=X&strikePrice=Y&optionType={call|put}` </br>

For sake of comparision, the same service is running on the application surface at /quoteorigin. This call can be directed to a specific GTM origin as explained above via the `origin={{username}|edgenative|legacy}` query string argument. </br>

**Observability**</br>
The Ion Property has DataStream2 enabled, and sends complete CDN logs to Hydrolix TrafficPeak. When viewing dashboards in TrafficPeak, of particular interest is changes in Edge Turn-Around Time (measuring origin response latency) as requests switch from using distributed to centralized origins and back.

**Performance Tests**</br>
There are two pages that can test in realtime the performance delta between deployment types. </br>

API Comparison - *https://workshop.connected-cloud.io/scoreboard/api-compare.html* - this makes an API call to `/get?topic=price`, and uses the origin query string to direct Akamai to use the edge-native origin vs. the centralized origin, and shows the results on a bar graph. </br>
Function Comparison - *https://workshop.connected-cloud.io/scoreboard/function-compare.html* - This runs the Option Pricing function, and directs the call to the Akamai EdgeWorker, as well as to hosted functions on both the edge-native and centralized origin, and shows the response time difference. </br>
Performance data can also be generated by running a distributed locust.io test, as scripted in this repository - *https://github.com/ccie7599/locust-edgenative*, and viewing the Edge Turn-Around Time panel in TrafficPeak. As scripted, including the /get (for edge-native) or /getlegacy (for centralized) in the path panel filter in TrafficPeak will contrast the turn-around time when using edge-native vs. centralized origins.

### Step 10 - Play the Game!
Go to https://workshop.connected-cloud.io/scoreboard.



