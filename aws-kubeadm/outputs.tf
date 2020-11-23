output "kubeconfig" {
  value       = module.k8s.kubeconfig
  description = "Location of the kubeconfig file for the created cluster on the local machine."
}

output "cluster_nodes" {
  value       = module.k8s.cluster_nodes
  description = "Name, public and private IP address, and subnet ID of the nodes of the created cluster."
}
