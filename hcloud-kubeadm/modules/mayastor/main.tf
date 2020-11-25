resource "null_resource" "server_upload_dir" {
  triggers = {
    k8s_master_ip     = var.k8s_master_ip
    server_upload_dir = var.server_upload_dir
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = ["mkdir -p \"${self.triggers.server_upload_dir}\""]
  }
}

// Set label openebs.io/engine=mayastor on all cluster nodes - we want to run MSN on all nodes
resource "null_resource" "mayastor_node_label" {
  for_each = toset(var.node_names)
  triggers = {
    k8s_master_ip = var.k8s_master_ip
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = ["kubectl label node \"${each.key}\" openebs.io/engine=mayastor"]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl label node \"${each.key}\" openebs.io/engine-"]
  }
}

// FIXME it would be nice to have yamls in HCL; but rather to have them in mayadata repo as snippets or TF module
resource "null_resource" "mayastor" {
  depends_on = [null_resource.mayastor_node_label]
  triggers = {
    k8s_master_ip = var.k8s_master_ip
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = [
      "kubectl create -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/namespace.yaml",
      "kubectl create -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/moac-rbac.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/master/csi/moac/crds/mayastorpool.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/nats-deployment.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/csi-daemonset.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/moac-deployment.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/mayastor-daemonset.yaml",
      "sleep 10",
    ]
  }
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/mayastor-daemonset.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/moac-deployment.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/csi-daemonset.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/nats-deployment.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/master/csi/moac/crds/mayastorpool.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/moac-rbac.yaml",
      "kubectl delete -f https://raw.githubusercontent.com/openebs/Mayastor/master/deploy/namespace.yaml",
    ]
  }
}

resource "null_resource" "mayastor_use_develop_images" {
  count      = var.mayastor_use_develop_images ? 1 : 0
  depends_on = [null_resource.mayastor]
  triggers = {
    k8s_master_ip = var.k8s_master_ip
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "remote-exec" {
    inline = [
      "kubectl -n mayastor patch daemonsets.apps mayastor --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"mayastor\",\"image\":\"mayadata/mayastor:develop\"}]}}}}",
      "kubectl -n mayastor patch daemonsets.apps mayastor-csi --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"mayastor-csi\",\"image\":\"mayadata/mayastor-csi:develop\"}]}}}}",
      "kubectl -n mayastor patch deployment.apps moac --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"moac\",\"image\":\"mayadata/moac:develop\"}]}}}}'",
    ]
  }
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "kubectl -n mayastor patch daemonsets.apps mayastor --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"mayastor\",\"image\":\"mayadata/mayastor:latest\"}]}}}}",
      "kubectl -n mayastor patch daemonsets.apps mayastor-csi --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"mayastor-csi\",\"image\":\"mayadata/mayastor-csi:latest\"}]}}}}",
      "kubectl -n mayastor patch deployment.apps moac --patch '{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"moac\",\"image\":\"mayadata/moac:latest\"}]}}}}'",
    ]
  }
}

resource "null_resource" "mayastor-pool-local" {
  depends_on = [null_resource.mayastor]
  for_each   = toset(var.node_names)
  triggers = {
    k8s_master_ip = var.k8s_master_ip
    mayastor_pool_local_yaml = templatefile("${path.module}/templates/mayastor-pool-local.yaml", {
      mayastor_disk = var.mayastor_disk,
      node          = each.key,
    }),
    server_upload_dir = var.server_upload_dir
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "file" {
    content     = self.triggers.mayastor_pool_local_yaml
    destination = "${self.triggers.server_upload_dir}/mayastor_pool_local-${each.key}.yaml"
  }
  provisioner "remote-exec" {
    inline = ["kubectl apply -f \"${self.triggers.server_upload_dir}/mayastor_pool_local-${each.key}.yaml\""]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f \"${self.triggers.server_upload_dir}/mayastor_pool_local-${each.key}.yaml\""]
  }
}

resource "null_resource" "mayastor-storageclass-nvme" {
  depends_on = [null_resource.mayastor-pool-local]
  triggers = {
    k8s_master_ip = var.k8s_master_ip
    mayastor_storageclass_local_yaml = templatefile("${path.module}/templates/mayastor-storageclass-nvme.yaml", {
      replicas = length(var.node_names),
    }),
    server_upload_dir = var.server_upload_dir
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "file" {
    content     = self.triggers.mayastor_storageclass_local_yaml
    destination = "${self.triggers.server_upload_dir}/mayastor_storageclass_nvme.yaml"
  }
  provisioner "remote-exec" {
    inline = ["kubectl apply -f \"${self.triggers.server_upload_dir}/mayastor_storageclass_nvme.yaml\""]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f \"${self.triggers.server_upload_dir}/mayastor_storageclass_nvme.yaml\""]
  }
}

