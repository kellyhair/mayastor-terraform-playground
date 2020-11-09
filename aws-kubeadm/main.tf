terraform {
  required_version = ">= 0.13"
}

provider "aws" {
  region = var.region
}

module "network" {
  source     = "weibeld/kubeadm/aws//modules/network"
  version    = "~> 0.2"
  cidr_block = "10.0.0.0/16"
  tags       = { "terraform-kubeadm:cluster" = module.cluster.cluster_name }
}

module "cluster" {
  // Temporarily commented out until the module is fixed
  //source    = "weibeld/kubeadm/aws"
  //version   = "~> 0.2"
  source    = "./kubeadm"
  vpc_id    = module.network.vpc_id
  subnet_id = module.network.subnet_id
  master_instance_type = "t3.medium"
  worker_instance_type = "t3.medium"
  num_workers = var.num_workers
  private_key_file = var.private_key_file
  public_key_file = var.public_key_file
  pod_network_cidr_block = "172.20.0.0/16"
}

// Cluster module creates a cluster without CNI. We must install it.
resource "null_resource" "cni" {
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key_file)
    host = element(module.cluster.cluster_nodes, 0).public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl --kubeconfig=admin.conf apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml"
    ]
  }
  depends_on = [module.cluster]
}

// Data volume for each worker node for a storage pool
resource "aws_ebs_volume" "ebs_data_volume" {
  count = var.num_workers
  availability_zone = var.availability_zone
  size = var.size
  tags = { "terraform-kubeadm:cluster" = module.cluster.cluster_name }
}

resource "aws_volume_attachment" "ebs_data_volume_attachment" {
  count = var.num_workers
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs_data_volume[count.index].id
  instance_id = aws_instance.workers[count.index].id
  tags = { "terraform-kubeadm:cluster" = module.cluster.cluster_name }
}

module "mayastor" {
  source = "./mod/mayastor"
  workers = [
    for worker in slice(module.cluster.cluster_nodes, 1, length(module.cluster.cluster_nodes)):
    worker.public_ip
  ]
  private_key_file = var.private_key_file
  depends_on = [module.cluster]
}
