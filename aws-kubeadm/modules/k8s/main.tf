# note 10.96/12 is used as a default service network in k8s - avoid collision
locals {
  tags         = merge(var.tags, { "terraform-kubeadm:cluster" = var.cluster_name, "Name" = var.cluster_name })
  flannel_cidr = "10.244.0.0/16" # hardcoded in flannel, do not change
}

#------------------------------------------------------------------------------#
# Security groups
#------------------------------------------------------------------------------#

# The AWS provider removes the default "allow all "egress rule from all security
# groups, so it has to be defined explicitly.
resource "aws_security_group" "egress" {
  name        = "${var.cluster_name}-egress"
  description = "Allow all outgoing traffic to everywhere"
  vpc_id      = aws_vpc.main.id
  tags        = local.tags
  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// FIXME: flannel runs in overlay mode - this is not needed but see TODO - use non-overlay networking.
resource "aws_security_group" "ingress_internal" {
  name        = "${var.cluster_name}-ingress-internal"
  description = "Allow all incoming traffic from nodes and Pods in the cluster"
  vpc_id      = aws_vpc.main.id
  tags        = local.tags
  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    self        = true
    description = "Allow incoming traffic from cluster nodes"

  }
  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [local.flannel_cidr]
    description = "Allow incoming traffic from the Pods of the cluster"
  }
}

resource "aws_security_group" "ingress_k8s" {
  name        = "${var.cluster_name}-ingress-k8s"
  description = "Allow incoming Kubernetes API requests (TCP/6443) from outside the cluster"
  vpc_id      = aws_vpc.main.id
  tags        = local.tags
  ingress {
    protocol    = "tcp"
    from_port   = 6443
    to_port     = 6443
    cidr_blocks = var.allowed_k8s_cidr_blocks
  }
}

resource "aws_security_group" "ingress_ssh" {
  name        = "${var.cluster_name}-ingress-ssh"
  description = "Allow incoming SSH traffic (TCP/22) from outside the cluster"
  vpc_id      = aws_vpc.main.id
  tags        = local.tags
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }
}

#------------------------------------------------------------------------------#
# Elastic IP for master node
#------------------------------------------------------------------------------#

# EIP for master node because it must know its public IP during initialisation
resource "aws_eip" "master" {
  vpc  = true
  tags = local.tags
}

resource "aws_eip_association" "master" {
  allocation_id = aws_eip.master.id
  instance_id   = aws_instance.master.id
}

#------------------------------------------------------------------------------#
# Bootstrap token for kubeadm
#------------------------------------------------------------------------------#

# Generate bootstrap token
# See https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

locals {
  token = "${random_string.token_id.result}.${random_string.token_secret.result}"
}

#------------------------------------------------------------------------------#
# EC2 instances
#------------------------------------------------------------------------------#

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # AWS account ID of Canonical
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "main" {
  key_name_prefix = "${var.cluster_name}-"
  public_key      = lookup(var.ssh_public_keys["key1"], "key_file", "__missing__") == "__missing__" ? lookup(var.ssh_public_keys["key1"], "key_data") : file(lookup(var.ssh_public_keys["key1"], "key_file"))
  tags            = local.tags
}

resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.image_id
  instance_type = var.master_instance_type
  subnet_id     = aws_subnet.main.id
  key_name      = aws_key_pair.main.key_name
  vpc_security_group_ids = [
    aws_security_group.egress.id,
    aws_security_group.ingress_internal.id,
    aws_security_group.ingress_k8s.id,
    aws_security_group.ingress_ssh.id
  ]
  tags        = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-master" })
  volume_tags = merge(local.tags, { "terraform-kubeadm:node" = "master", "Name" = "${var.cluster_name}-master" })
  user_data = <<-EOF
  #!/bin/bash

  set -e

  ${templatefile("${path.module}/templates/machine-bootstrap.sh", {
  docker_version : var.docker_version,
  hostname : "${var.cluster_name}-master",
  kubernetes_version : var.kubernetes_version,
  ssh_public_keys : var.ssh_public_keys,
  user : "ubuntu",
})}

  # Run kubeadm
  kubeadm init \
    --token "${local.token}" \
    --token-ttl 15m \
    --apiserver-cert-extra-sans "${aws_eip.master.public_ip}" \
    --pod-network-cidr "${local.flannel_cidr}" \
    --node-name master

  # Prepare kubeconfig file for download to local machine
  mkdir -p /home/ubuntu/.kube
  cp /etc/kubernetes/admin.conf /home/ubuntu
  cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config # enable kubectl on the node
  sudo mkdir /root/.kube
  sudo cp /etc/kubernetes/admin.conf /root/.kube/config
  chown ubuntu:ubuntu /home/ubuntu/admin.conf /home/ubuntu/.kube/config

  # prepare kube config for download
  kubectl --kubeconfig /home/ubuntu/admin.conf config set-cluster kubernetes --server https://${aws_eip.master.public_ip}:6443

  # Indicate completion of bootstrapping on this node
  touch /home/ubuntu/done
  EOF
}

resource "aws_instance" "workers" {
  count                       = var.num_workers
  ami                         = data.aws_ami.ubuntu.image_id
  instance_type               = var.worker_instance_type
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids = [
    aws_security_group.egress.id,
    aws_security_group.ingress_internal.id,
    aws_security_group.ingress_ssh.id
  ]
  ebs_block_device {
    device_name           = "/dev/sdh" # FIXME: seems not used at all, disk is always /dev/nvme1n1, but using nvme1n1 fails ?!
    volume_size           = var.ebs_volume_size
    delete_on_termination = true
    encrypted             = false
  }
  tags        = merge(local.tags, { "terraform-kubeadm:node" = "worker-${count.index}", "Name" = "${var.cluster_name}-worker-${count.index}" })
  volume_tags = merge(local.tags, { "terraform-kubeadm:node" = "worker-${count.index}", "Name" = "${var.cluster_name}-worker-${count.index}" })
  user_data = <<-EOF
  #!/bin/bash

  set -e

  ${templatefile("${path.module}/templates/machine-bootstrap.sh", {
  docker_version : var.docker_version,
  hostname : "${var.cluster_name}-worker-${count.index}",
  kubernetes_version : var.kubernetes_version,
  ssh_public_keys : var.ssh_public_keys,
  user : "ubuntu",
})}

  # Run kubeadm
  kubeadm join ${aws_instance.master.private_ip}:6443 \
    --token ${local.token} \
    --discovery-token-unsafe-skip-ca-verification \
    --node-name worker-${count.index}

  # Indicate completion of bootstrapping on this node
  touch /home/ubuntu/done
  EOF
}

#------------------------------------------------------------------------------#
# Wait for bootstrap to finish on all nodes
#------------------------------------------------------------------------------#

resource "null_resource" "wait_for_bootstrap_to_finish" {
  provisioner "local-exec" {
    command = <<-EOF
    alias ssh='ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    while true; do
      sleep 2
      ! ssh ubuntu@${aws_eip.master.public_ip} [[ -f /home/ubuntu/done ]] >/dev/null && continue
      %{for worker_public_ip in aws_instance.workers[*].public_ip~}
      ! ssh ubuntu@${worker_public_ip} [[ -f /home/ubuntu/done ]] >/dev/null && continue
      %{endfor~}
      break
    done
    EOF
  }
  triggers = {
    instance_ids = join(",", concat([aws_instance.master.id], aws_instance.workers[*].id))
  }
}

#------------------------------------------------------------------------------#
# Download kubeconfig file from master node to local machine
#------------------------------------------------------------------------------#

locals {
  kubeconfig_file = var.kubeconfig_file != null ? abspath(pathexpand(var.kubeconfig_file)) : "${abspath(pathexpand(var.kubeconfig_dir))}/${var.cluster_name}.conf"
}

resource "null_resource" "download_kubeconfig_file" {
  provisioner "local-exec" {
    command = <<-EOF
    set -e
    scp -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_eip.master.public_ip}:/home/ubuntu/admin.conf ${local.kubeconfig_file} >/dev/null
    EOF
  }
  triggers = {
    wait_for_bootstrap_to_finish = null_resource.wait_for_bootstrap_to_finish.id
  }
}

resource "null_resource" "flannel" {
  # well ... FIXME?
  # I like to have flannel removable/upgradeable via TF, but stuff required to SSH to the instance for destroy is destroyed before flannel :-/
  depends_on = [aws_eip_association.master, null_resource.wait_for_bootstrap_to_finish, aws_instance.master, aws_internet_gateway.main, aws_route_table.main, aws_route_table_association.main]
  triggers = {
    host            = aws_eip.master.public_ip
    flannel_version = var.flannel_version
  }
  connection {
    host = self.triggers.host
  }

  // NOTE: admin.conf is copied to ubuntu's home by kubeadm module
  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f \"https://raw.githubusercontent.com/coreos/flannel/v${self.triggers.flannel_version}/Documentation/kube-flannel.yml\""
    ]
  }

  # FIXME: deleting flannel's yaml isn't enough to undeploy it completely (e.g. /etc/cni/net.d/*, ...)
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "kubectl delete -f \"https://raw.githubusercontent.com/coreos/flannel/v${self.triggers.flannel_version}/Documentation/kube-flannel.yml\""
    ]
  }
}
