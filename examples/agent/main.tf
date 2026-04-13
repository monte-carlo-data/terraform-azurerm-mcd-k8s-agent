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
