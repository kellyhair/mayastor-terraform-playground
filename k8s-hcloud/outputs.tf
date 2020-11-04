output "master_ips" {
  value = module.iaas.master_ips
}

output "node_ips" {
  value = module.iaas.node_ips
}

output "k8s_admin_conf" {
  value = module.iaas.k8s_admin_conf
}
