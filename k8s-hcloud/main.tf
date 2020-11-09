module "iaas" {
  source = "./modules/iaas"

  hcloud_csi_token = var.hcloud_csi_token
  hcloud_fip_token = var.hcloud_fip_token
  hcloud_token     = var.hcloud_token
  hetzner_location = var.hetzner_location

  server_upload_dir = var.server_upload_dir

  master_count = var.master_count
  node_count   = var.node_count

  cluster_networking = var.cluster_networking
}

module "paas" {
  depends_on = [module.iaas]

  source = "./modules/paas"

  k8s_admin_conf    = module.iaas.k8s_admin_conf
  k8s_master_ip     = module.iaas.master_ips[0]
  masters           = module.iaas.masters
  node_ips          = module.iaas.node_ips
  nodes             = module.iaas.nodes
  server_upload_dir = var.server_upload_dir
}

