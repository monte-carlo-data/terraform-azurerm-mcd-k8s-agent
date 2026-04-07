module "mcd_on_prem_agent" {
  source = "../../"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"
  helm                = { chart_version = "0.0.2" }
}

output "cluster_name" {
  value = module.mcd_on_prem_agent.cluster_name
}

output "resource_group_name" {
  value = module.mcd_on_prem_agent.resource_group_name
}

output "storage_account_name" {
  value = module.mcd_on_prem_agent.storage_account_name
}

output "key_vault_url" {
  value = module.mcd_on_prem_agent.key_vault_url
}

output "managed_identity_client_id" {
  value = module.mcd_on_prem_agent.managed_identity_client_id
}
