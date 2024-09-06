terraform {
  required_providers {
    linode = {
      source = "linode/linode"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "userid" {
  description = "User ID or identifier to be used in labels and tags"
  type        = string
}
variable "me6" {
  description = "IPv6 Address of current jumphost"
  type        = string
}
variable "me" {
  description = "IPv4 Address of the current Jumphost"
  type        = string
} 

variable "regions" {
  description = "List of regions to create Linodes in"
  type        = list(string)
}
locals {
   raw_cidrs = file("${path.module}/ipv4.txt")
   cleaned_cidrs = [for cidr in split(",", local.raw_cidrs) : trimspace(replace(cidr, "\"", ""))
  ]
   raw_ipv6_cidrs = file("${path.module}/ipv6.txt")
   cleaned_ipv6_cidrs = [for cidr in split(",", local.raw_ipv6_cidrs) : trimspace(replace(cidr, "\"", ""))
  ]
}
locals {
  # Generate current Unix epoch time for timestamp
  timestamp = formatdate("s", timestamp())
}

data "local_file" "ssh_key" {
  filename = "/home/${var.userid}/.ssh/id_rsa.pub"
}

locals {
  # Remove newlines from the SSH key content
  sanitized_ssh_key = replace(data.local_file.ssh_key.content, "\n", "")
}

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
                                                                                                                                                                                       
output "ip_address" {
  value = [for vm in linode_instance.linode : "${vm.ipv4}"]                                                                                                                            
}
                                                                                                                                                                                       
locals {
  ip_address = [for vm in linode_instance.linode : "${vm.ipv4}"]
  jp_osa_ip_address = [for vm in linode_instance.linode : vm.ipv4 if vm.region == "jp-osa"]
  osaka_ip_address = flatten([for vm in linode_instance.linode : vm.ipv4 if vm.region == "jp-osa"])
  all_ip_addresses = flatten([for vm in linode_instance.linode : "${vm.ipv4}"])
  region_ip_pairs = { for instance in linode_instance.linode : instance.region => instance.ip_address }
  }
output "all_ip_addresses" {
  value = local.all_ip_addresses
}
resource "null_resource" "create-invs" {
  triggers = {
    instance_ids = join(",", linode_instance.linode.*.id)
  }
  provisioner "local-exec" {
    command = <<EOT
      chmod +x ${path.module}/nats_config.sh
      ./nats_config.sh
    EOT
  }
  depends_on = [linode_instance.linode]
}
resource "null_resource" "copy_files" {
  triggers = {
    instance_ids = join(",", linode_instance.linode.*.id)
  }
  count = length(local.all_ip_addresses) 
  connection {
    type = "ssh"
    host = local.all_ip_addresses[count.index]
    user = "root"
    private_key = file("/home/${var.userid}/.ssh/id_rsa")
  }
  provisioner "file" {
    source = "/etc/fullchain.pem"
    destination = "/etc/fullchain.pem"
  }
  provisioner "file" {
    source = "/etc/privkey.pem"
    destination = "/etc/privkey.pem"
  }
  provisioner "file" {
    source = "${path.module}/nats.conf"
    destination = "/root/nats.conf"
  }
  provisioner "remote-exec" {
    inline = [
      "rm -rf /root/start-nats.sh",
      "echo '#!/bin/bash' > /root/start-nats.sh",
      "echo 'pid=$(ps -ef | grep nats-server | grep -v grep | awk \"{print \\$2}\")' >> /root/start-nats.sh",
      "echo 'if [ ! -z \"$pid\" ]; then' >> /root/start-nats.sh",
      "echo '  kill -9 $pid' >> /root/start-nats.sh",
      "echo 'fi' >> /root/start-nats.sh",
      "echo 'nats-server -c /root/nats.conf --cluster_name nats_global --name \"$(hostname)\" &' >> /root/start-nats.sh",
      "echo 'echo \"Starting NATS server...\"' >> /root/start-nats.sh",
      "chmod +x /root/start-nats.sh",
      "./start-nats.sh",
      "rm -rf /root/start-docker.sh",
      "echo '#!/bin/bash' > /root/start-docker.sh",
      "echo 'if [ ! $(docker volume ls -q -f name=app-vol) ]; then' >> /root/start-docker.sh",
      "echo '  echo \"Creating Docker volume app-vol...\"' >> /root/start-docker.sh",
      "echo '  docker volume create app-vol' >> /root/start-docker.sh",
      "echo 'fi' >> /root/start-docker.sh",
      "echo 'if [ ! $(docker ps -q -f name=edge-trader) ]; then' >> /root/start-docker.sh",
      "echo '  echo \"Starting edge-trader container...\"' >> /root/start-docker.sh",
      "echo '  docker run -d --restart always --add-host host.docker.internal:172.17.0.1 --name edge-trader -m 512m -v app-vol:/data -v /tmp/db:/db -v /etc:/certs -p 443:443 brianapley/edge-trader' >> /root/start-docker.sh",
      "echo 'fi' >> /root/start-docker.sh",
      "echo 'if [ ! $(docker ps -q -f name=node-http) ]; then' >> /root/start-docker.sh",
      "echo '  echo \"Starting node-http container...\"' >> /root/start-docker.sh",
      "echo '  docker run -d --restart always --name node-http -m 512m -v /tmp/db:/tmp/db -v /etc:/etc -p 8443:8443 brianapley/node-http' >> /root/start-docker.sh",
      "echo 'fi' >> /root/start-docker.sh",
      "chmod +x /root/start-docker.sh",
      "./start-docker.sh",
    ]
  }
  depends_on = [linode_instance.linode, null_resource.create-invs, linode_firewall.nats_firewall]
}
resource "null_resource" "connector" {
  connection {
    type = "ssh"
    host = local.osaka_ip_address[0]
    user = "root"
    private_key = file("/home/${var.userid}/.ssh/id_rsa")
  }
  provisioner "remote-exec" {
    inline = [
      "docker run -d --restart always --add-host host.docker.internal:172.17.0.1 --name connector -m 1024m brianapley/redis-nats",
    ]
  }
  depends_on = [linode_instance.linode, null_resource.create-invs]
}
resource "null_resource" "create_gtm_tf" {
  triggers = {
    instance_ids = join(",", linode_instance.linode.*.id)
  }
  provisioner "local-exec" {
    command = <<EOT
#!/bin/bash  
output_file="/gtm-data/${var.userid}.tf"
static_file="${path.module}/static.txt"
# Create the base of the .tf file from static.txt
cp "$static_file" "$output_file"
sed -i "s/{userid}/${var.userid}/g" "$output_file"
# Append dynamic region IP blocks
region_ip_pairs="${join(" ", [for region, ip in local.region_ip_pairs : "${region}=${ip}"])}"
for pair in $region_ip_pairs; do
    region=$(echo "$pair" | cut -d= -f1)
    ip_address=$(echo "$pair" | cut -d= -f2)
    cat >> "$output_file" <<EOF
  traffic_target {
  datacenter_id = akamai_gtm_datacenter.$region.datacenter_id
  enabled       = true
  weight        = 0
  servers       = ["$ip_address"]
  }
EOF
done  
# Append the final closing brace to the file 
echo "}" >> "$output_file"
EOT
  }
}
