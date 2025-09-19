terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###########################################################
# Network Interface
resource "aws_network_interface" "cluster_nic" {
  subnet_id       = var.subnets[count.index % length(var.availability_zones)].id
  security_groups = var.security_groups
  count           = var.worker_count

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-cluster-nic-${count.index}"
  })
}

###########################################################
# EC2
resource "aws_instance" "node" {
  ami = var.machine_image
  instance_type = var.machine_type
  availability_zone = sort(var.availability_zones)[count.index % length(var.availability_zones)]
  key_name = var.ssh_key_name
  count    = var.worker_count

  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.cluster_nic[count.index].id
  }

  root_block_device {
    volume_size           = var.boot_disk_size
    volume_type           = var.boot_disk_type
    delete_on_termination = true
  }

  user_data = <<-EOF
  #! /bin/bash
  echo "$(date) - CREATING SSH key" >> /home/${var.ssh_user}/install_crdb.log
  sudo -u ${var.ssh_user} bash -c 'echo "${file(var.ssh_public_key)}" >> ~/.ssh/authorized_keys'

  echo "$(date) - PREPARING machine node" >> /home/${var.ssh_user}/install_crdb.log
  apt-get -y update
  apt-get -y install vim
  apt-get -y install iotop
  apt-get -y install iputils-ping

  apt-get install -y netcat
  apt-get install -y dnsutils
  export DEBIAN_FRONTEND=noninteractive
  export TZ="UTC"
  apt-get install -y tzdata
  ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
  dpkg-reconfigure --frontend noninteractive tzdata

  # cloud instance have no swap anyway
  #swapoff -a
  #sed -i.bak '/ swap / s/^(.*)$/#1/g' /etc/fstab
  echo 'DNSStubListener=no' | tee -a /etc/systemd/resolved.conf
  mv /etc/resolv.conf /etc/resolv.conf.orig
  ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
  service systemd-resolved restart
  sysctl -w net.ipv4.ip_local_port_range="40000 65535"
  echo "net.ipv4.ip_local_port_range = 40000 65535" >> /etc/sysctl.conf

  sudo yum erase 'ntp*'
  sudo yum install chrony
  echo 'server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4' | sudo tee -a /etc/chrony.conf
  sudo service chronyd restart
  sudo chkconfig chronyd on

  binaries="${var.cockroach_release}"
  filename=$${binaries##*/}
  packagename=$${filename%.*}
  mkdir /home/${var.ssh_user}/install
  echo "$(date) - PREPARE done" >> /home/${var.ssh_user}/install_crdb.log

  ################
  # CRDB

  echo "$(date) - DOWNLOADING CockroachDB from : " ${var.cockroach_release} >> /home/${var.ssh_user}/install_crdb.log
  wget "${var.cockroach_release}" -P /home/${var.ssh_user}/install
  sudo tar xvf /home/${var.ssh_user}/install/$filename -C /home/${var.ssh_user}/install/

  echo "$(date) - INSTALLING CockroachDB" >> /home/${var.ssh_user}/install_crdb.log
  cd /home/${var.ssh_user}/install
  sudo cp -i $packagename/cockroach /usr/local/bin/
  sudo mkdir -p /usr/local/lib/cockroach
  sudo cp -i $packagename/lib/libgeos.so /usr/local/lib/cockroach/
  sudo cp -i $packagename/lib/libgeos_c.so /usr/local/lib/cockroach/

  sleep 10
  echo "$(date) - INSTALL done" >> /home/${var.ssh_user}/install_crdb.log

  ################
  # NODE

  node_external_addr=`curl ifconfig.me/ip`
  echo "Node ${count.index + 1} : $node_external_addr" >> /home/${var.ssh_user}/install_crdb.log
  echo "joining cluster " >> /home/${var.ssh_user}/install_crdb.log
  command="cockroach start --insecure --locality=region=${var.region},zone=${sort(var.availability_zones)[count.index % length(var.availability_zones)]} --store=cockroach-data-${count.index + 1} --advertise-addr=${aws_network_interface.cluster_nic[count.index].private_ip}:26257 --http-addr=${aws_network_interface.cluster_nic[count.index].private_ip}:8080 --join=${join(",", formatlist("%s:26257", var.cluster_join_ips))} --background"
  echo "$command" >> /home/${var.ssh_user}/install_crdb.log
  sudo bash -c "$command 2>&1" >> /home/${var.ssh_user}/install_crdb.log

  is_init=${var.init}
  if [ ${count.index + 1} -eq ${var.worker_count} ]; then
    if $is_init ; then
      echo "initializing cluster..." >> /home/${var.ssh_user}/install_crdb.log
      sleep ${((var.worker_count * 3) *  10)}
      command="cockroach init --host localhost:26257 --insecure"
      echo "$command" >> /home/${var.ssh_user}/install_crdb.log
      sudo bash -c "$command 2>&1" >> /home/${var.ssh_user}/install_crdb.log
    fi
  fi
  echo "$(date) - DONE creating cluster node" >> /home/${var.ssh_user}/install_crdb.log
  Footer
  EOF

  tags = merge("${var.resource_tags}",{
    Name = "${var.name}-node-${count.index}"
  })
}

# target groups attachment
resource "aws_lb_target_group_attachment" "tg_sql_attach" {
  count            = var.worker_count
  target_group_arn = var.sql_load_balancer_arn
  target_id        = aws_instance.node[count.index].id
}

resource "aws_lb_target_group_attachment" "tg_console_attach" {
  count            = var.worker_count
  target_group_arn = var.console_load_balancer_arn
  target_id        = aws_instance.node[count.index].id
}