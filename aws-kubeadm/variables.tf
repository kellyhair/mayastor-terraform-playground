variable "region" {
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

variable "size" {
  type        = number
  description = "Size of data EBS volume in GB"
  default     = 1
}
variable "private_key_file" {
  type        = string
  description = "Filename of the private key of a key pair on your local machine. This key pair will allow to connect to the nodes of the cluster with SSH."
  default     = "~/.ssh/id_rsa"
}

variable "public_key_file" {
  type        = string
  description = "Filename of the public key of a key pair on your local machine."
  default     = "~/.ssh/id_rsa.pub"
}
