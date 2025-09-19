terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

############################################################
# Network Interface

resource "aws_network_interface" "nic" {
  subnet_id       = var.subnet
  security_groups = var.security_groups

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-client-nic"
  })
}


# Elastic IP to the Network Interface
resource "aws_eip" "eip" {
  network_interface         = aws_network_interface.nic.id
  associate_with_private_ip = aws_network_interface.nic.private_ip
  depends_on                = [aws_instance.bastion]

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-client-eip"
  })
}


############################################################
# EC2
resource "aws_instance" "bastion" {
  ami               = var.machine_image 
  instance_type     = var.machine_type
  availability_zone = var.availability_zone
  key_name          = var.ssh_key_name
  depends_on        = [var.dependencies]

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-client"
  })

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.nic.id
  }

  user_data = <<-EOF
  #!/bin/bash
  echo "$(date) - 📦 Preparing client" >> /home/${var.ssh_user}/prepare_client.log
  export DEBIAN_FRONTEND=noninteractive
  export TZ="UTC"
  ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
  apt-get -y install vim iotop iputils-ping netcat-openbsd bind9-dnsutils tzdata build-essential autoconf automake libevent-dev pkg-config zlib1g-dev libssl-dev
  dpkg-reconfigure --frontend noninteractive tzdata
  binaries="${var.cockroach_release}"
  filename=$${binaries##*/}
  packagename=$${filename%.*}
  mkdir /home/${var.ssh_user}/install
  echo "$(date) - 📥 Downloading CockroachDB from : " ${var.cockroach_release} >> /home/${var.ssh_user}/prepare_client.log
  wget "${var.cockroach_release}" -P /home/${var.ssh_user}/install
  sudo tar xvf /home/${var.ssh_user}/install/$filename -C /home/${var.ssh_user}/install/
  echo "$(date) - 🛠  Installing CockroachDB 🪳" >> /home/${var.ssh_user}/prepare_client.log
  cd /home/${var.ssh_user}/install
  sudo cp -i $packagename/cockroach /usr/local/bin/
  sudo mkdir -p /usr/local/lib/cockroach
  sudo cp -a $packagename/lib/. /usr/local/lib/cockroach/
  sleep 10
  echo "$(date) - ✅ CRDB installation completed." >> /home/${var.ssh_user}/prepare_client.log 2>&1
  yes | sudo sudo snap install go --classic >> /home/${var.ssh_user}/prepare_client.log 2>&1
  sudo go get -u golang.org/x/sys
  echo "$(date) - ✅ Golang installation completed." >> /home/${var.ssh_user}/prepare_client.log 2>&1
  echo "$(date) - 🛠  Installing Docker 🐳" >> /home/${var.ssh_user}/prepare_client.log
  sudo apt update
  sudo apt -y install apt-transport-https ca-certificates curl software-properties-common
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
  sudo apt -y install docker-ce
  sudo groupadd docker
  sudo usermod -aG docker ${var.ssh_user}
  sudo systemctl restart docker
  sudo chmod 666 /var/run/docker.sock
  sudo apt -y install docker-compose
  echo "$(date) - ✅ Docker installation completed." >> /home/${var.ssh_user}/prepare_client.log 2>&1
  echo "$(date) - ⏳ Waiting for CRDB Cluster to respond..." >> /home/${var.ssh_user}/prepare_client.log 2>&1
  status_code=$(curl --write-out '%%{http_code}' --silent  --output /dev/null "http://${var.cluster_fqdn}:8080")
  while [ "$status_code" != "200" ]; do
      echo "🔄 Retry in 20 seconds..." >> /home/${var.ssh_user}/prepare_client.log
      sleep 20
      status_code=$(curl --write-out '%%{http_code}' --silent  --output /dev/null "http://${var.cluster_fqdn}:8080")
  done
  echo "$(date) - ✅ CRDB Cluster is Up." >> /home/${var.ssh_user}/prepare_client.log 2>&1
  echo "$(date) - 💰 Configure Cluster's License" >> /home/${var.ssh_user}/prepare_client.log
  name=$${repository##*/}
  foldername=$${name%.*}
  cd /home/${var.ssh_user}/$foldername
  command="cockroach sql --url postgresql://root@${var.cluster_fqdn}:26257 --insecure --execute=\"SET CLUSTER SETTING cluster.organization = '${var.cluster_organization}'\""
  echo "$command" >> /home/${var.ssh_user}/prepare_client.log
  sudo bash -c "$command 2>&1" >> /home/${var.ssh_user}/prepare_client.log
  command="cockroach sql --url postgresql://root@${var.cluster_fqdn}:26257 --insecure --execute=\"SET CLUSTER SETTING enterprise.license = '${var.cluster_license}';\""
  echo "$command" >> /home/${var.ssh_user}/prepare_client.log
  sudo bash -c "$command 2>&1" >> /home/${var.ssh_user}/prepare_client.log
  echo "$(date) - ✅ CRDB Cluster license is active." >> /home/${var.ssh_user}/prepare_client.log 2>&1
  echo "$(date) - ✏️  Create SpiceDB schema" >> /home/${var.ssh_user}/prepare_client.log
  command="cockroach sql --url postgresql://root@${var.cluster_fqdn}:26257 --insecure --execute=\"CREATE DATABASE IF NOT EXISTS spicedb;\""
  echo "$command" >> /home/${var.ssh_user}/prepare_client.log
  sudo bash -c "$command 2>&1" >> /home/${var.ssh_user}/prepare_client.log
  echo "$(date) - ✅ SpiceDB schema created." >> /home/${var.ssh_user}/prepare_client.log 2>&1
  echo "$(date) - 📦 Install SpiceDB" >> /home/${var.ssh_user}/prepare_client.log
  sudo apt update && sudo apt install -y curl ca-certificates gpg
  curl https://pkg.authzed.com/apt/gpg.key | sudo apt-key add -
  sudo echo "deb https://pkg.authzed.com/apt/ * *" > /etc/apt/sources.list.d/fury.list
  sudo apt update && sudo apt install -y spicedb
  echo "$(date) - ✅ SpiceDB is installed." >> /home/${var.ssh_user}/prepare_client.log 2>&1
  echo "$(date) - ✏️  Setting SpiceDB datastore" >> /home/${var.ssh_user}/prepare_client.log 2>&1
  sudo spicedb datastore migrate head --datastore-engine=cockroachdb --datastore-conn-uri="postgres://root@${var.cluster_fqdn}:26257/spicedb?sslmode=disable"
  command="spicedb serve --grpc-preshared-key="${var.preshared_key}" --http-enabled=true --datastore-engine=cockroachdb --datastore-conn-uri=postgres://root@${var.cluster_fqdn}:26257/spicedb?sslmode=disable &"
  sudo bash -c "$command 2>&1" >> /home/${var.ssh_user}/prepare_client.log
  echo "✅ SpiceDB is up." >> /home/${var.ssh_user}/prepare_client.log 2>&1

  echo "$(date) - 💯 Client setting Completed" >> /home/${var.ssh_user}/prepare_client.log
  EOF

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }
}