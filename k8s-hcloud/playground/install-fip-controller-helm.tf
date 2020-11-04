resource "kubernetes_namespace" "fip-controller" {
  metadata {
    name = "fip-controller"
  }
}

data "helm_repository" "cbeneke" {
  name = "cbeneke"
  url  = "https://cbeneke.github.com/helm-charts"
}

resource "helm_release" "fip-controller" {
  name       = "fip-controller"
  chart      = "cbeneke/hcloud-fip-controller"
  namespace  = "fip-controller"
  depends_on = [hcloud_server.master, hcloud_floating_ip.erp_ingress_ip]

  set {
    name  = "hcloud_floating_ips"
    value = "{ ${hcloud_floating_ip.dashboards_ingress_ip.ip_address}, ${hcloud_floating_ip.erp_ingress_ip.ip_address}, ${hcloud_floating_ip.mqtts_ingress_ip.ip_address} }"
  }

  set {
    name  = "hcloud_api_token"
    value = var.hcloud_fip_token
  }

  set {
    name  = "lease_duration"
    value = 30
  }

  set {
    name = "lease_name"
    # FIXME: something useful - doc states prod - which I presume means env for multi-env k8s clusters
    value = "hcloud_fip_lease_name"
  }

  set {
    name  = "log_level"
    value = "info"
  }
}
