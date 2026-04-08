module "mcd_on_prem_agent" {
  source = "../../"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"
  helm                = { chart_version = "0.0.2" }

  # Create a new AKS cluster in an existing VNet
  networking = {
    create_vnet                          = false
    existing_subnet_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/aks-subnet"
    existing_vnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet"
    existing_private_endpoints_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/pe-subnet"
  }
}

output "cluster_endpoint" {
  value = module.mcd_on_prem_agent.cluster_endpoint
}

output "cluster_name" {
  value = module.mcd_on_prem_agent.cluster_name
}

output "storage_account_name" {
  value = module.mcd_on_prem_agent.storage_account_name
}

output "key_vault_url" {
  value = module.mcd_on_prem_agent.key_vault_url
}
