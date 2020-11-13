
output "client_certificate" {
  value = azurerm_kubernetes_cluster.mayastor.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.mayastor.kube_config_raw
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.mayastor.node_resource_group
}
