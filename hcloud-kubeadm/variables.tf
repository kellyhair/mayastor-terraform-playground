variable "hcloud_token" {}
variable "hcloud_csi_token" {}

variable "hetzner_location" { default = "hel1" }

variable "node_count" { default = 2 }

# terraform provisioner remote-exec sometimes need a file, it's uploaded into
# server_upload_dir first
variable "server_upload_dir" { default = "/root/tf-upload" }

variable "hugepages_2M_amount" {
  description = "Amount of 2M hugepages to enable system-wide; mayastor requires at least 512 2M hugepages for itself"
  default     = 640
}

variable "admin_ssh_keys" {
  description = "Map of maps for configuring ssh keys. Keys are key names in hcloud values are maps with either key_file which is read or key_data which is used verbatim."
  default = {
    "key1" : { "key_file" = "~/.ssh/id_ed25519.pub" },
    "key2" : { "key_data" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMQCA+Slye+ZcgLRxdIyQCpEcG/XKKwyxpRWuCSpS098 email@example.com" },
  }
}

