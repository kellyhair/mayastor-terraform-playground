
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

# yeah, it seems azure supports only one key :(
variable "public_key" {
  type        = map
  description = "Map containing either public key filename under 'key_file' or contents under 'key_data'"
  default     = { "key_file" : "~/.ssh/id_rsa.pub" }
}
