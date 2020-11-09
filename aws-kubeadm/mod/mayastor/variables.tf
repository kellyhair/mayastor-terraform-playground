
variable "private_key_file" {
  type        = string
  description = "Filename of the private key of a key pair on your local machine. This key pair will allow to connect to the nodes of the cluster with SSH."
  default     = "~/.ssh/id_rsa"
}

variable "user" {
  type        = string
  description = "User name for ssh access (must have sudo)"
  default     = "ubuntu"
}

variable "workers" {
  type        = list(string)
  description = "A list of IP addresses of worker nodes"
  default     = []
}

variable "nr_hugepages" {
  type        = number
  description = "Number of 2MB hugepages to allocate on the worker node"
  default     = 512
}
