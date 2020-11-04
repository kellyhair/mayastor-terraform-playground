resource "kubernetes_secret" "hcloud_csi_token" {
  depends_on = [hcloud_server.master]
  metadata {
    name      = "hcloud-csi"
    namespace = "kube-system"
  }

  data = {
    token = var.hcloud_csi_token
  }
}


resource "null_resource" "hcloud_csi" {
  depends_on = [kubernetes_secret.hcloud_csi_token]
  triggers = {
    hcloud_master      = hcloud_server.master.0.ipv4_address
    hcloud_csi_version = var.hcloud_csi_version
  }
  connection {
    host = self.triggers.hcloud_master
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v${self.triggers.hcloud_csi_version}/deploy/kubernetes/hcloud-csi.yml"]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v${self.triggers.hcloud_csi_version}/deploy/kubernetes/hcloud-csi.yml"]
  }

}
