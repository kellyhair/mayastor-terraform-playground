# FIXME: fix auth to kubelet and don't use --deprecated-kubelet-completely-insecure
resource "null_resource" "metrics_server" {
  depends_on = [hcloud_server.master, hcloud_server.node]
  triggers = {
    k8s_master_ip          = hcloud_server.master.ipv4_address
    metrics_server_version = var.metrics_server_version
    server_upload_dir      = var.server_upload_dir

    patch_yaml = templatefile("${path.module}/templates/metrics_server_patch.yaml.tmpl", {
      "master" : hcloud_server.master.name,
      "master_ip" : hcloud_server.master.ipv4_address,
      "node_ips" : [for node in hcloud_server.node : node.ipv4_address],
      "nodes" : [for node in hcloud_server.node : node.name],
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

