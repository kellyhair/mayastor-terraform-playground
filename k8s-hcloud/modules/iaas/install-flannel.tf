resource "null_resource" "flannel" {
  triggers = {
    hcloud_master     = hcloud_server.master[0].ipv4_address
    server_upload_dir = var.server_upload_dir
  }
  connection {
    host = self.triggers.hcloud_master
  }

  provisioner "file" {
    source      = "${path.module}/files/kube-flannel-wireguard.yaml"
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

