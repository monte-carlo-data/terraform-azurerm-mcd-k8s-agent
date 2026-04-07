output "resource_group_name" {
  description = "Resource group name."
  value       = local.effective_resource_group_name
}

output "cluster_name" {
  description = "AKS cluster name."
  value       = local.effective_cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for AKS control plane."
  value       = var.cluster.create ? azurerm_kubernetes_cluster.mcd_agent[0].kube_config[0].host : null
  sensitive   = true
}

output "storage_account_name" {
  description = "Storage account name for agent data."
  value       = local.effective_storage_account_name
}

output "storage_container_name" {
  description = "Storage container name for agent data."
  value       = local.effective_storage_container_name
}

output "key_vault_url" {
  description = "Key Vault URL for agent secrets."
  value       = local.effective_key_vault_url
}

output "managed_identity_client_id" {
  description = "Client ID of the user assigned managed identity."
  value       = azurerm_user_assigned_identity.mcd_agent.client_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the user assigned managed identity."
  value       = azurerm_user_assigned_identity.mcd_agent.principal_id
}

output "namespace" {
  description = "Kubernetes namespace for the agent."
  value       = local.namespace
}

output "private_endpoint_id" {
  description = "ID of the Monte Carlo Private Link endpoint."
  value       = var.private_link != null ? azurerm_private_endpoint.monte_carlo[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the Monte Carlo Private Link endpoint."
  value       = var.private_link != null ? azurerm_private_endpoint.monte_carlo[0].private_service_connection[0].private_ip_address : null
}

output "helm_values" {
  description = "Helm values used for agent deployment. Use these for manual Helm deployment when deploy_agent is false."
  value       = local.helm_values_yaml
}
