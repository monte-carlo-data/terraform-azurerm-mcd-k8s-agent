module "mcd_on_prem_agent" {
  source = "../../"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"

  # Create a new AKS cluster in an existing VNet
  networking = {
    create_vnet        = false
    existing_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.Network/virtualNetworks/my-vnet/subnets/my-subnet"
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
