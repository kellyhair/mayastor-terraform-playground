
variable "location" {
  type        = string
  description = "Location in which to create the cluster."
  default     = "West Europe"
}

variable "num_workers" {
  type        = number
  description = "Number of worker nodes in k8s cluster"
  default     = 1
}

variable "public_key_file" {
  type        = string
  description = "Filename of the public key of a key pair on your local machine."
  default     = "~/.ssh/id_rsa.pub"
}
