# --- Standalone Variables ---

variable "location" {
  description = "The Azure region to deploy resources into."
  type        = string
  default     = "westus"
}

variable "backend_service_url" {
  description = "The Monte Carlo backend service URL. Obtain this from Monte Carlo -> Account information -> Agent Service -> Public endpoint (or Private link endpoint if using PrivateLink)."
  type        = string
}

# --- Grouped Object Variables ---

variable "cluster" {
  description = "AKS cluster configuration."
  type = object({
    create                               = optional(bool, true)
    name                                 = optional(string, null)
    existing_cluster_name                = optional(string, null)
    existing_cluster_resource_group_name = optional(string, null)
    kubernetes_version                   = optional(string, "1.34")
    default_node_pool = optional(object({
      vm_size    = string
      node_count = number
    }), { vm_size = "Standard_DS2_v2", node_count = 1 })
    oidc_issuer_enabled       = optional(bool, true)
    workload_identity_enabled = optional(bool, true)
    service_cidr              = optional(string, "172.16.0.0/16")
    dns_service_ip            = optional(string, "172.16.0.10")
  })
  default = {}

  validation {
    condition     = var.cluster.create || (var.cluster.existing_cluster_name != null && var.cluster.existing_cluster_resource_group_name != null)
    error_message = "Both existing_cluster_name and existing_cluster_resource_group_name are required when cluster.create is false."
  }
}

variable "resource_group" {
  description = "Resource group configuration."
  type = object({
    existing_name = optional(string, null)
  })
  default = {}
}

variable "networking" {
  description = "Networking configuration."
  type = object({
    create_vnet                               = optional(bool, true)
    vnet_address_space                        = optional(list(string), ["10.18.0.0/16"])
    subnet_address_prefixes                   = optional(list(string), ["10.18.0.0/24"])
    existing_subnet_id                        = optional(string, null)
    existing_vnet_id                          = optional(string, null)
    private_endpoints_subnet_address_prefixes = optional(list(string), ["10.18.1.0/24"])
    existing_private_endpoints_subnet_id      = optional(string, null)
  })
  default = {}

  validation {
    condition     = var.networking.create_vnet || var.networking.existing_subnet_id != null
    error_message = "existing_subnet_id is required when networking.create_vnet is false."
  }
}

variable "storage" {
  description = "Storage account configuration."
  type = object({
    create_account                       = optional(bool, true)
    existing_account_name                = optional(string, null)
    existing_account_resource_group_name = optional(string, null)
    existing_container_name              = optional(string, null)
    account_replication_type             = optional(string, "GRS")
    min_tls_version                      = optional(string, "TLS1_2")
  })
  default = {}

  validation {
    condition     = var.storage.create_account || (var.storage.existing_account_name != null && var.storage.existing_account_resource_group_name != null && var.storage.existing_container_name != null)
    error_message = "existing_account_name, existing_account_resource_group_name, and existing_container_name are required when storage.create_account is false."
  }
}

variable "token_secret" {
  description = "Key Vault and token secret store configuration."
  type = object({
    create_key_vault                       = optional(bool, true)
    existing_key_vault_name                = optional(string, null)
    existing_key_vault_resource_group_name = optional(string, null)
    existing_key_vault_url                 = optional(string, null)
    tenant_id                              = optional(string, null)
    name                                   = optional(string, "mcd-agent-token")
  })
  default = {}

  validation {
    condition     = var.token_secret.create_key_vault || (var.token_secret.existing_key_vault_name != null && var.token_secret.existing_key_vault_resource_group_name != null && var.token_secret.existing_key_vault_url != null)
    error_message = "existing_key_vault_name, existing_key_vault_resource_group_name, and existing_key_vault_url are required when token_secret.create_key_vault is false."
  }
}

variable "token_credentials" {
  description = "MCD agent token credentials. Set to populate the secret at deploy time, or leave empty to set manually later."
  type = object({
    mcd_id    = optional(string, null)
    mcd_token = optional(string, null)
  })
  sensitive = true
  default   = {}
}

variable "integration_secrets" {
  description = "Integration secrets to sync from the cloud secret store."
  type = list(object({
    secret_key     = string
    remote_ref_key = string
  }))
  default = []
}

variable "agent" {
  description = "Agent runtime configuration."
  type = object({
    namespace     = optional(string, "mcd-agent")
    image         = optional(string, "montecarlodata/agent:latest-generic")
    pull_policy   = optional(string, "Always")
    replica_count = optional(number, 1)
  })
  default = {}
}

variable "helm" {
  description = "Helm deployment configuration."
  type = object({
    deploy_agent                      = optional(bool, true)
    install_external_secrets_operator = optional(bool, true)
    chart_repository                  = optional(string, "oci://registry-1.docker.io/montecarlodata")
    chart_name                        = optional(string, "generic-agent-helm")
    chart_version                     = string
    service_annotations               = optional(map(string), {})
    enabled_logs_collector            = optional(bool, true)
    enabled_metrics_collector         = optional(bool, true)
  })
}

variable "private_link" {
  description = "Azure Private Link configuration for connecting to the Monte Carlo backend via a private endpoint. When set, creates a private endpoint, private DNS zone, and VNet link. The Private Link Service resource ID and subresource name can be obtained from Monte Carlo -> Account information -> Agent Service -> Azure private link."
  type = object({
    private_link_service_resource_id = string
    subresource_names                = optional(list(string), [])
  })
  default = null
}

variable "custom_values" {
  description = "Custom Helm values to merge with module-generated values. Accepts any map matching the chart's values.yaml schema. NOTE: merge is shallow — overriding a nested object (e.g. `container`) replaces it entirely, dropping module-generated keys like `backendServiceUrl` and `storageAccountName`. When overriding nested objects, include all required keys."
  type        = any
  default     = {}
}

variable "custom_default_tags" {
  description = "Custom tags to apply to all resources. Merged with default Monte Carlo agent tags."
  type        = map(string)
  default     = {}
}
