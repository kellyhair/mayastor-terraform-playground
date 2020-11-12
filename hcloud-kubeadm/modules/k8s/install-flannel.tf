resource "null_resource" "flannel" {
  triggers = {
    flannel_yaml = templatefile("${path.module}/templates/kube-flannel-wireguard.yaml", {
      pod_network_cidr = var.pod_network_cidr,
    }),
    hcloud_master     = hcloud_server.master.ipv4_address
    server_upload_dir = var.server_upload_dir
  }
  connection {
    host = self.triggers.hcloud_master
  }

  provisioner "file" {
    content     = self.triggers.flannel_yaml
    destination = "${self.triggers.server_upload_dir}/kube-flannel-wireguard.yaml"
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f \"${self.triggers.server_upload_dir}/kube-flannel-wireguard.yaml\""]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f \"${self.triggers.server_upload_dir}/kube-flannel-wireguard.yaml\""]
  }
}

