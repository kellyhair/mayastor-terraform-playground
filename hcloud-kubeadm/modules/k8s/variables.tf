variable "hcloud_token" {}
variable "hetzner_location" {}
variable "hcloud_csi_token" {}

variable "server_upload_dir" {}

variable "admin_ssh_keys" {}

variable "master_image" { default = "ubuntu-20.04" }
variable "master_type" { default = "cx21" }
variable "node_count" {}
variable "node_image" { default = "ubuntu-20.04" }
variable "node_type" { default = "cx21" }

variable "docker_version" { default = "19.03" }
variable "kubernetes_version" { default = "1.18.9" }
variable "feature_gates" {
  description = "Add Feature Gates e.g. 'DynamicKubeletConfig=true'"
  default     = ""
}
variable "hcloud_csi_version" { default = "1.4.0" }

variable "pod_network_cidr" { default = "10.244.0.0/16" }

variable "metrics_server_version" { default = "0.3.7" }

variable "hugepages_2M_amount" {}
