output "master_ip" {
  value = module.k8s.master_ip
}

output "node_ips" {
  value = module.k8s.node_ips
}

output "k8s_admin_conf" {
  value = module.k8s.k8s_admin_conf
}
