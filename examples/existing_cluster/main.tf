provider "azurerm" {
  features {}
  storage_use_azuread = true
}

variable "mcd_id" {
  description = "Monte Carlo agent ID."
  type        = string
  sensitive   = true
}

variable "mcd_token" {
  description = "Monte Carlo agent token."
  type        = string
  sensitive   = true
}

module "mcd_on_prem_agent" {
  source = "../../"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"
  helm                = { chart_version = "0.0.2" }

  token_credentials = {
    mcd_id    = var.mcd_id
    mcd_token = var.mcd_token
  }

  # Use an existing AKS cluster
  cluster = { create = false, existing_cluster_name = "my-existing-cluster", existing_cluster_resource_group_name = "my-existing-rg" }
  networking = {
    create_vnet                          = false
    existing_subnet_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/aks-subnet"
    existing_vnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet"
    existing_private_endpoints_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/pe-subnet"
  }
}

output "storage_account_name" {
  value = module.mcd_on_prem_agent.storage_account_name
}

output "helm_values" {
  value     = module.mcd_on_prem_agent.helm_values
  sensitive = true
}
