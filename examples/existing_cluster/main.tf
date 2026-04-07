module "mcd_on_prem_agent" {
  source = "../../"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"

  # Use an existing AKS cluster
  cluster    = { create = false, existing_cluster_name = "my-existing-cluster", existing_cluster_resource_group_name = "my-existing-rg" }
  networking = { create_vnet = false }
}

output "storage_account_name" {
  value = module.mcd_on_prem_agent.storage_account_name
}

output "helm_values" {
  value     = module.mcd_on_prem_agent.helm_values
  sensitive = true
}
