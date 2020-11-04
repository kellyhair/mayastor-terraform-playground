variable "hcloud_token" {}
variable "hetzner_location" {}
variable "hcloud_csi_token" {}
variable "hcloud_fip_token" {}

variable "server_upload_dir" {}

# WARNING: key must be stored in modules/iaas/files/ssh-keys
variable "admin_ssh_keys" {
  type = list
  default = [
    { name = "antonin_kral", key_file = "antonin_kral.pub" },
    { name = "arne_rusek", key_file = "arne_rusek.pub" },
  ]
}

variable "master_count" {}
variable "master_image" {
  default = "debian-10"
}
variable "master_type" {
  default = "cx21"
}
variable "node_count" {}
variable "node_image" {
  default = "debian-10"
}
variable "node_type" { default = "cx21" }

variable "docker_version" { default = "19.03" }
variable "kubernetes_version" { default = "1.18.9" }
variable "feature_gates" {
  description = "Add Feature Gates e.g. 'DynamicKubeletConfig=true'"
  default     = ""
}
variable "hcloud_csi_version" { default = "1.4.0" }
# TODO: see IMPORTANT in changelog when upgrading https://github.com/cbeneke/hcloud-fip-controller/blob/v0.4.0/CHANGELOG.md
# WARNING: testing 0.4.0 - when node went down floating IP wasn't moved and when unassigned was assigned back to node that was down!
variable "hcloud_fip_version" { default = "0.3.5" }

variable "cluster_networking" { default = "flannel" }
# Note: these are respective providers defaults in their deployment yamls
variable "pod_network_cidr" {
  default = { "calico" = "192.168.0.0/16", "flannel" = "10.244.0.0/16" }
}
variable "calico_version" { default = "3.8" }

