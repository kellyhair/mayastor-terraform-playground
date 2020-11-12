provider "azurerm" {
  version = ">= 2.2"
  features {}
}

locals {
  datadir     = "data"
  environment = "mayastor-test"
  kubeconfig  = "${local.datadir}/kubectl.conf"
}

resource "azurerm_resource_group" "mayastor" {
  name     = "mayastor-aks"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "mayastor" {
  name                = "mayastor-aks"
  location            = azurerm_resource_group.mayastor.location
  resource_group_name = azurerm_resource_group.mayastor.name
  dns_prefix          = "mayastor-aks"

  linux_profile {
    admin_username = "mayastor"
    ssh_key {
      key_data = lookup(var.public_key, "key_file", "__missing__") == "__missing__" ? lookup(var.public_key, "key_data") : file(lookup(var.public_key, "key_file"))
    }
  }

  default_node_pool {
    name       = "default"
    node_count = 1 // this is scaled down later, but we cannot create cluster with 0 nodes (it can be scaled to 0 so why?)
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = local.environment
  }
}

// NOTE: local.datadir is kept
resource "null_resource" "store_kubeconfig" {
  depends_on = [azurerm_kubernetes_cluster.mayastor]

  triggers = {
    datadir    = local.datadir
    kubeconfig = local.kubeconfig
  }

  provisioner "local-exec" {
    command = "mkdir -p \"${self.triggers.datadir}\""
  }

  provisioner "local-exec" {
    command = "echo '${azurerm_kubernetes_cluster.mayastor.kube_config_raw}' > \"${local.kubeconfig}\""
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm \"${self.triggers.kubeconfig}\""
  }
}

resource "null_resource" "setup_workers" {
  depends_on = [null_resource.store_kubeconfig]

  provisioner "local-exec" {
    command = "${path.module}/scripts/setup_workers.sh"
    environment = {
      ENVIRONMENT = local.environment
      KUBECONFIG  = local.kubeconfig
      NUM_WORKERS = var.num_workers
    }
  }
}

