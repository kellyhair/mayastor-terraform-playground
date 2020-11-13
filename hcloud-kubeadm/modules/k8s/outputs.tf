output "master_ip" {
  value = hcloud_server.master.ipv4_address
}

output "nodes" {
  value = [for node_srv in hcloud_server.node : node_srv.name]
}

output "node_ips" {
  value = [for node_srv in hcloud_server.node : node_srv.ipv4_address]
}

output "k8s_admin_conf" {
  value = "${path.module}/secrets/admin.conf"
}
