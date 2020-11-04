resource "null_resource" "k8s_dashboard" {
  triggers = {
    k8s_master_ip         = var.k8s_master_ip
    k8s_dashboard_version = var.k8s_dashboard_version
    server_upload_dir     = var.server_upload_dir
  }
  connection {
    host = self.triggers.k8s_master_ip
  }

  # FIXME - use server_upload_dir
  provisioner "file" {
    source      = "${path.module}/files/dashboard-access.yaml"
    destination = "${self.triggers.server_upload_dir}/dashboard-access.yaml"
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v${self.triggers.k8s_dashboard_version}/aio/deploy/recommended.yaml"]
  }
  provisioner "remote-exec" {
    inline = ["kubectl apply -f ${self.triggers.server_upload_dir}/dashboard-access.yaml"]
  }
  # k8s dashboard uses self-signed cert and doesn't open http port, this is to signal voyager how to configure ingress (not configured here)
  provisioner "remote-exec" {
    inline = ["kubectl annotate service kubernetes-dashboard -n kubernetes-dashboard ingress.appscode.com/backend-tls='ssl verify none'"]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f ${self.triggers.server_upload_dir}/dashboard-access.yaml"]
  }
  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v${self.triggers.k8s_dashboard_version}/aio/deploy/recommended.yaml"]
  }
}

