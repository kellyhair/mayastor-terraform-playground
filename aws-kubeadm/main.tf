resource "random_pet" "cluster_name" {
  length    = 2
  separator = "-"
}

module "k8s" {
  source = "./modules/k8s"

  cluster_name = var.cluster_name == null ? random_pet.cluster_name.id : var.cluster_name
  num_workers  = var.num_workers

  aws_region           = var.aws_region
  docker_version       = var.docker_version
  flannel_version      = var.flannel_version
  kubernetes_version   = var.kubernetes_version
  master_instance_type = var.master_instance_type
  worker_instance_type = var.worker_instance_type

  ssh_public_keys = var.ssh_public_keys

  tags = var.tags
}

module "mayastor-dependencies" {
  count  = var.deploy_mayastor ? 1 : 0
  source = "./modules/mayastor-dependencies"
  workers = {
    for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) :
    worker.name => worker.public_ip
  }
  depends_on = [module.k8s]
}

module "mayastor" {
  count             = var.deploy_mayastor ? 1 : 0
  depends_on        = [module.mayastor-dependencies, module.k8s]
  source            = "./modules/mayastor"
  k8s_master_ip     = module.k8s.cluster_nodes[0].public_ip
  node_names        = [for worker in slice(module.k8s.cluster_nodes, 1, length(module.k8s.cluster_nodes)) : worker.name]
  server_upload_dir = "/root/tf-upload"
  mayastor_disk     = "/dev/nvme1n1"
}
