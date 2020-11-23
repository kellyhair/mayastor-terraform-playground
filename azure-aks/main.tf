
provider "azurerm" {
  version = ">= 2.2"
  features {}
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
      key_data = file(var.public_key_file)
    }
  }

  default_node_pool {
    name       = "default"
    node_count = var.num_workers
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Test"
  }
}
