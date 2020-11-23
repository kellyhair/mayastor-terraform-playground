variable "aws_region" {
  type        = string
  description = "AWS region in which to create the cluster."
  default     = "eu-central-1"
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone where EBS data volumes will be created."
  default     = "eu-central-1a"
}

variable "num_workers" {
  type        = number
  description = "Number of worker nodes in k8s cluster"
  default     = 2
}

// default = {
//     "key1" : { "key_file" = "~/.ssh/id_rsa.pub" },
//     "key2" : { "key_data" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQCA+Slye+ZcgLRxdIyQCpEcG/XKKwyxpRWuCSpS098 email@example.com" },
// }
variable "ssh_public_keys" {
  type        = map
  description = "Map of maps of public ssh keys. See variables.tf for full example. Default is ~/.ssh/id_rsa.pub"
  default = {
    "key1" : { "key_file" = "~/.ssh/id_rsa.pub" },
  }
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster. Used as a part of AWS names and tags of various cluster components."
  default     = null
}

variable "tags" {
  type        = map
  description = "A set of tags to assign to the created AWS resources. These tags will be assigned in addition to the default tags. The default tags include \"terraform-kubeadm:cluster\" which is assigned to all resources and whose value is the cluster name, and \"terraform-kubeadm:node\" which is assigned to the EC2 instances and whose value is the name of the Kubernetes node that this EC2 corresponds to."
  default     = {}
}

variable "master_instance_type" {
  type        = string
  description = "AWS instance type for master node."
  default     = "t3.medium"
}

variable "worker_instance_type" {
  type        = string
  description = "AWS instance type for worker node."
  default     = "t3.medium"
}

variable "flannel_version" {
  type        = string
  description = "Version of flannel CNI to deploy to the cluster."
  default     = "0.13.0"
}

variable "docker_version" {
  type        = string
  description = "Docker version to install."
  default     = "19.03"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to install."
  default     = "1.19.4"
}

variable "deploy_mayastor" {
  type        = bool
  description = "Deploy mayastor dependencies (nvme-tcp kernel module, set up hugepages) and mayastor itself. Set to false to skip."
  default     = true
}

variable "ebs_volume_size" {
  type        = number
  description = "Additional EBS volume size to attach to EC2 instance on workers in gigabytes."
  default     = 5
}

