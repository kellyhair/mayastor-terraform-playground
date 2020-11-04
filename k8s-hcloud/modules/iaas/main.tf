provider "kubernetes" {
  config_path = "${path.module}/secrets/admin.conf"
  host        = "https://${hcloud_server.master.0.ipv4_address}:6443/"
}

resource "hcloud_ssh_key" "admin_ssh_keys" {
  count      = length(var.admin_ssh_keys)
  name       = lookup(var.admin_ssh_keys[count.index], "name")
  public_key = file("${path.module}/files/ssh-keys/${lookup(var.admin_ssh_keys[count.index], "key_file")}")
}

resource "hcloud_server" "master" {
  count       = var.master_count
  name        = "master-${count.index + 1}"
  server_type = var.master_type
  image       = var.master_image
  ssh_keys    = [for key in hcloud_ssh_key.admin_ssh_keys : key.id]
  depends_on  = []
  location    = var.hetzner_location

  connection {
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = ["mkdir ${var.server_upload_dir}"]
  }

  # upgrade to current kernel
  provisioner "file" {
    source      = "${path.module}/scripts/kernel-upgrade.sh"
    destination = "${var.server_upload_dir}/kernel-upgrade.sh"
  }
  provisioner "remote-exec" {
    inline = ["bash ${var.server_upload_dir}/kernel-upgrade.sh"]
  }
  # there's a sleep 2 && reboot run by kernel-upgrade.sh, wait a bit to avoid
  # connecting to machine going down
  provisioner "local-exec" {
    command = "sleep 5"
  }

  provisioner "file" {
    source      = "${path.module}/files/10-kubeadm.conf"
    destination = "${var.server_upload_dir}/10-kubeadm.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap.sh"
    destination = "${var.server_upload_dir}/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = ["DOCKER_VERSION=\"${var.docker_version}\" KUBERNETES_VERSION=\"${var.kubernetes_version}\" SERVER_UPLOAD_DIR=\"${var.server_upload_dir}\" bash \"${var.server_upload_dir}/bootstrap.sh\""]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/master.sh"
    destination = "${var.server_upload_dir}/master.sh"
  }

  provisioner "remote-exec" {
    inline = ["FEATURE_GATES=\"${var.feature_gates}\" POD_NETWORK_CIDR=\"${lookup(var.pod_network_cidr, var.cluster_networking)}\" bash \"${var.server_upload_dir}/master.sh\""]
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/copy-kubeadm-token.sh"

    environment = {
      SSH_USERNAME = "root"
      SSH_HOST     = hcloud_server.master[0].ipv4_address
      TARGET       = "${path.module}/secrets/"
    }
  }
}

resource "hcloud_server" "node" {
  count       = var.node_count
  name        = "node-${count.index + 1}"
  server_type = var.node_type
  image       = var.node_image
  depends_on  = [hcloud_server.master]
  ssh_keys    = [for key in hcloud_ssh_key.admin_ssh_keys : key.id]
  location    = var.hetzner_location

  connection {
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = ["mkdir ${var.server_upload_dir}"]
  }

  # upgrade to current kernel
  provisioner "file" {
    source      = "${path.module}/scripts/kernel-upgrade.sh"
    destination = "${var.server_upload_dir}/kernel-upgrade.sh"
  }
  provisioner "remote-exec" {
    inline = ["bash ${var.server_upload_dir}/kernel-upgrade.sh"]
  }
  # there's a sleep 2 && reboot run by kernel-upgrade.sh, wait a bit to avoid
  # connecting to machine going down
  provisioner "local-exec" {
    command = "sleep 5"
  }

  provisioner "file" {
    source      = "${path.module}/files/10-kubeadm.conf"
    destination = "${var.server_upload_dir}/10-kubeadm.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap.sh"
    destination = "${var.server_upload_dir}/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = ["DOCKER_VERSION=\"${var.docker_version}\" KUBERNETES_VERSION=\"${var.kubernetes_version}\" SERVER_UPLOAD_DIR=\"${var.server_upload_dir}\" bash \"${var.server_upload_dir}/bootstrap.sh\""]
  }

  provisioner "file" {
    source      = "${path.module}/secrets/kubeadm_join"
    destination = "/tmp/kubeadm_join"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/node.sh"
    destination = "${var.server_upload_dir}/node.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash ${var.server_upload_dir}/node.sh"]
  }
}

resource "null_resource" "configure_fip" {
  count = length(concat(
    [for master_srv in hcloud_server.master : master_srv.ipv4_address],
    [for node_srv in hcloud_server.node : node_srv.ipv4_address]
  ))
  triggers = {
    server_ip = concat(
      [for master_srv in hcloud_server.master : master_srv.ipv4_address],
      [for node_srv in hcloud_server.node : node_srv.ipv4_address]
    )[count.index]
    configure_fip_sh = templatefile("${path.module}/templates/configure-fip.sh", {
    })
  }

  connection {
    host = self.triggers.server_ip
  }

  provisioner "remote-exec" {
    inline = ["mkdir ${var.server_upload_dir} -p"]
  }

  provisioner "file" {
    content     = self.triggers.configure_fip_sh
    destination = "${var.server_upload_dir}/configure-fip.sh"
  }

  provisioner "remote-exec" {
    inline = ["bash ${var.server_upload_dir}/configure-fip.sh"]
  }
}

# NOTE: null_resource.cluster_firewall is never destroyed (even if terraform does it it stays in effect on infra)
# FIXME: use map instead of setunion in for_each to allow nice naming of firewall resources
resource "null_resource" "cluster_firewall_master" {
  triggers = {
    k8s_master_ipv4       = hcloud_server.master[0].ipv4_address
    k8s_nodes_ipv4        = join(" ", [for node in hcloud_server.node : node.ipv4_address])
    # force redeploy on script change
    deploy_script_sha = filesha256("${path.module}/scripts/generate-firewall.sh")
  }

  connection {
    host = self.triggers.k8s_master_ipv4
  }

  provisioner "file" {
    source      = "${path.module}/scripts/generate-firewall.sh"
    destination = "${var.server_upload_dir}/generate-firewall.sh"
  }

  provisioner "remote-exec" {
    inline = ["MASTER=true k8s_master_ipv4=\"${self.triggers.k8s_master_ipv4}\" k8s_nodes_ipv4=\"${self.triggers.k8s_nodes_ipv4}\" bash ${var.server_upload_dir}/generate-firewall.sh"]
  }

}
resource "null_resource" "cluster_firewall_node" {
  count = var.node_count
  triggers = {
    k8s_master_ipv4       = hcloud_server.master[0].ipv4_address
    k8s_nodes_ipv4        = join(" ", [for node in hcloud_server.node : node.ipv4_address])
    # force redeploy on script change
    deploy_script_sha = filesha256("${path.module}/scripts/generate-firewall.sh")
  }

  connection {
    host = hcloud_server.node[count.index].ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/scripts/generate-firewall.sh"
    destination = "${var.server_upload_dir}/generate-firewall.sh"
  }

  provisioner "remote-exec" {
    inline = ["MASTER=false k8s_master_ipv4=\"${self.triggers.k8s_master_ipv4}\" k8s_nodes_ipv4=\"${self.triggers.k8s_nodes_ipv4}\" bash ${var.server_upload_dir}/generate-firewall.sh"]
  }

}
