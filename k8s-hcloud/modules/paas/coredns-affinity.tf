resource "null_resource" "coredns_affinity" {
  triggers = {
    k8s_master_ip     = var.k8s_master_ip
    server_upload_dir = var.server_upload_dir
    replicas          = length(var.masters) + length(var.nodes) # one pod per node
    coredns_patch     = file("${path.module}/files/coredns_patch.yaml")
  }
  connection {
    host = self.triggers.k8s_master_ip
  }
  provisioner "file" {
    content     = self.triggers.coredns_patch
    destination = "${self.triggers.server_upload_dir}/coredns_patch.yaml"
  }
  provisioner "remote-exec" {
    inline = ["kubectl -n kube-system patch deployment coredns --patch \"$(cat ${self.triggers.server_upload_dir}/coredns_patch.yaml)\""]
  }
  provisioner "remote-exec" {
    inline = ["kubectl -n kube-system scale deployment coredns --replicas=\"${self.triggers.replicas}\""]
  }
}
