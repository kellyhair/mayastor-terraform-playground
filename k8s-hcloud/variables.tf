variable "hcloud_token" {}
variable "hcloud_csi_token" {}
variable "hcloud_fip_token" {}

variable "hetzner_location" { default = "hel1" }

# FIXME: install scripts currently do not support multi-master setup
variable "master_count" { default = 1 }
variable "node_count" { default = 4 }

# flannel and calico supported
variable "cluster_networking" { default = "flannel" }

# terraform provisioner remote-exec sometimes need a file, it's uploaded into
# server_upload_dir first
variable "server_upload_dir" { default = "/root/tf-upload" }

