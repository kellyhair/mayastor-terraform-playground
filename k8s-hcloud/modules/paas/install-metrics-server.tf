# FIXME: fix auth to kubelet and don't use --deprecated-kubelet-completely-insecure
resource "null_resource" "metrics_server" {
  triggers = {
    k8s_dashboard_version  = var.k8s_dashboard_version
    k8s_master_ip          = var.k8s_master_ip
    metrics_server_version = var.metrics_server_version
    server_upload_dir      = var.server_upload_dir

    patch_yaml = templatefile("${path.module}/templates/metrics_server_patch.yaml.tmpl", {
      "master_ips" : [var.k8s_master_ip],
      "masters" : var.masters,
      "nodes" : var.nodes,
      "node_ips" : var.node_ips,
    })
  }
  connection {
    host = self.triggers.k8s_master_ip
  }

  provisioner "file" {
    content     = self.triggers.patch_yaml
    destination = "${self.triggers.server_upload_dir}/metrics_server_patch.yaml"
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v${self.triggers.metrics_server_version}/components.yaml"]
  }

  provisioner "remote-exec" {
    inline = ["kubectl -n kube-system patch deployment metrics-server --patch \"$(cat ${self.triggers.server_upload_dir}/metrics_server_patch.yaml)\""]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v${self.triggers.metrics_server_version}/components.yaml"]
  }
}

