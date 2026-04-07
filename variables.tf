# --- Standalone Variables ---

variable "location" {
  description = "The Azure region to deploy resources into."
  type        = string
  default     = "westus"
}

variable "backend_service_url" {
  description = "The Monte Carlo backend service URL. Obtain this from Monte Carlo support."
  type        = string
  default     = "https://artemis.dev.getmontecarlo.com"
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
  })
  default = {}
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
    create_vnet             = optional(bool, true)
    vnet_address_space      = optional(list(string), ["10.18.0.0/16"])
    subnet_address_prefixes = optional(list(string), ["10.18.0.0/24"])
    existing_subnet_id      = optional(string, null)
  })
  default = {}
}

variable "storage" {
  description = "Storage account configuration."
  type = object({
    create_account          = optional(bool, true)
    existing_account_name   = optional(string, null)
    existing_container_name = optional(string, null)
  })
  default = {}
}

variable "token_secret" {
  description = "Key Vault and token secret store configuration."
  type = object({
    create_key_vault       = optional(bool, true)
    existing_key_vault_url = optional(string, null)
    tenant_id              = optional(string, null)
    name                   = optional(string, "mcd-agent-token")
  })
  default = {}
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
    namespace               = optional(string, "mcd-agent")
    image                   = optional(string, "montecarlodata/pre-release-agent:latest-generic")
    replica_count           = optional(number, 1)
    gunicorn_workers        = optional(number, 1)
    gunicorn_threads        = optional(number, 1)
    ops_runner_thread_count = optional(number, 5)
    publisher_thread_count  = optional(number, 2)
    service_port            = optional(number, 8080)
    container_port          = optional(number, 8080)
    remote_upgradable       = optional(bool, true)
  })
  default = {}
}

variable "helm" {
  description = "Helm deployment configuration."
  type = object({
    deploy_agent                      = optional(bool, true)
    install_external_secrets_operator = optional(bool, true)
    chart_repository                  = optional(string, "oci://registry-1.docker.io/montecarlodata")
    chart_name                        = optional(string, "pre-release-generic-agent-helm")
    chart_version                     = optional(string, "0.0.1-rc193")
    service_annotations               = optional(map(string), {})
    enabled_logs_collector            = optional(bool, true)
    enabled_metrics_collector         = optional(bool, true)
  })
  default = {}
}

variable "custom_values" {
  description = "Custom Helm values to merge with module-generated values. Accepts any map matching the chart's values.yaml schema."
  type        = any
  default     = {}
}

variable "custom_default_tags" {
  description = "Custom tags to apply to all resources. Merged with default Monte Carlo agent tags."
  type        = map(string)
  default     = {}
}
