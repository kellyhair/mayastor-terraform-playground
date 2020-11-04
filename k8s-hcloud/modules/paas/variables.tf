variable "masters" {}
variable "node_ips" {}
variable "nodes" {}
variable "server_upload_dir" {}

variable "k8s_admin_conf" {}
variable "k8s_dashboard_version" { default = "2.0.0-beta8" }
variable "k8s_master_ip" {}
variable "metrics_server_version" { default = "0.3.7" }

