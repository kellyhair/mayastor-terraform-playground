# NOTE: calico uses --pod-network-cidr to 192.168.0.0/16 in
# modules/iaas/scripts/master.sh
# (see modules/iaas/variables.tf:pod_network_cidr)

resource "null_resource" "calico" {
  count = var.cluster_networking == "calico" ? 1 : 0

  depends_on = [hcloud_server.master]

  triggers = {
    calico_version = var.calico_version
    hcloud_master  = hcloud_server.master.0.ipv4_address
  }

  connection {
    host = self.triggers.hcloud_master
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://docs.projectcalico.org/v${self.triggers.calico_version}/manifests/calico.yaml"]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f https://docs.projectcalico.org/v${self.triggers.calico_version}/manifests/calico.yaml"]
  }

}

