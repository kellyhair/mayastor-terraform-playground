resource "kubernetes_namespace" "fip_controller" {
  depends_on = [hcloud_server.master]
  metadata {
    name = "fip-controller"
  }
}

resource "kubernetes_secret" "hcloud_fip_token" {
  metadata {
    name      = "fip-controller-secrets"
    namespace = kubernetes_namespace.fip_controller.metadata[0].name
  }
  data = {
    token = var.hcloud_fip_token
  }
}

# FIXME: use secret reference instead of directly using var.hcloud_api_token
resource "kubernetes_config_map" "fip_controller_config" {
  metadata {
    name      = "fip-controller-config"
    namespace = kubernetes_namespace.fip_controller.metadata[0].name
  }
  data = { # TODO add dashboard_ingress_ip
    "config.json" = "{\"hcloud_floating_ips\":[],\"lease_duration\":30,\"hcloud_api_token\":\"${var.hcloud_fip_token}\",\"log_level\":\"Debug\",\"node_address_type\":\"internal\"}"
  }
}

resource "null_resource" "hcloud_fip_rbac_daemonset" {
  depends_on = [kubernetes_config_map.fip_controller_config, kubernetes_secret.hcloud_fip_token]
  triggers = {
    hcloud_fip_version = var.hcloud_fip_version
    hcloud_master      = hcloud_server.master.0.ipv4_address
  }
  connection {
    host = self.triggers.hcloud_master
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/v${self.triggers.hcloud_fip_version}/deploy/rbac.yaml"]
  }

  provisioner "remote-exec" {
    inline = ["kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/v${self.triggers.hcloud_fip_version}/deploy/daemonset.yaml"]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/v${self.triggers.hcloud_fip_version}/deploy/rbac.yaml"]
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["kubectl delete -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/v${self.triggers.hcloud_fip_version}/deploy/daemonset.yaml"]
  }
}
