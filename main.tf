locals {
  mcd_agent_service_name    = "REMOTE_AGENT"
  mcd_agent_deployment_type = "TERRAFORM"

  cluster_name           = var.cluster.name != null ? var.cluster.name : "mcd-agent-${random_id.mcd_agent_id.hex}"
  effective_cluster_name = var.cluster.create ? azurerm_kubernetes_cluster.mcd_agent[0].name : var.cluster.existing_cluster_name
  namespace              = var.agent.namespace
  service_account_name   = "mcd-agent-service-account"

  default_tags = merge(var.custom_default_tags, {
    "mcd-agent-service-name"    = lower(local.mcd_agent_service_name)
    "mcd-agent-deployment-type" = lower(local.mcd_agent_deployment_type)
  })

  mcd_agent_naming_prefix               = "mcd-agent"
  mcd_agent_store_container_name        = "mcdstore"
  mcd_agent_store_data_prefix           = "mcd"
  effective_resource_group_name         = var.resource_group.existing_name != null ? var.resource_group.existing_name : azurerm_resource_group.mcd_agent[0].name
  effective_resource_group_location     = var.location
  effective_storage_account_name        = var.storage.create_account ? azurerm_storage_account.mcd_agent[0].name : var.storage.existing_account_name
  effective_storage_account_id          = var.storage.create_account ? azurerm_storage_account.mcd_agent[0].id : data.azurerm_storage_account.existing[0].id
  effective_storage_container_name      = var.storage.create_account ? azurerm_storage_container.mcd_agent[0].name : var.storage.existing_container_name
  effective_key_vault_url               = var.token_secret.create_key_vault ? azurerm_key_vault.mcd_agent[0].vault_uri : var.token_secret.existing_key_vault_url
  effective_key_vault_id                = var.token_secret.create_key_vault ? azurerm_key_vault.mcd_agent[0].id : data.azurerm_key_vault.existing[0].id
  effective_tenant_id                   = var.token_secret.tenant_id != null ? var.token_secret.tenant_id : data.azurerm_client_config.current.tenant_id
  effective_subnet_id                   = var.networking.create_vnet ? azurerm_subnet.mcd_agent[0].id : var.networking.existing_subnet_id
  effective_vnet_id                     = var.networking.create_vnet ? azurerm_virtual_network.mcd_agent[0].id : var.networking.existing_vnet_id
  effective_private_endpoints_subnet_id = var.networking.create_vnet ? azurerm_subnet.private_endpoints[0].id : var.networking.existing_private_endpoints_subnet_id
  effective_aks_oidc_issuer_url         = var.cluster.create ? azurerm_kubernetes_cluster.mcd_agent[0].oidc_issuer_url : data.azurerm_kubernetes_cluster.existing[0].oidc_issuer_url

  cluster_endpoint           = var.cluster.create ? azurerm_kubernetes_cluster.mcd_agent[0].kube_config[0].host : data.azurerm_kubernetes_cluster.existing[0].kube_config[0].host
  cluster_ca_certificate     = base64decode(var.cluster.create ? azurerm_kubernetes_cluster.mcd_agent[0].kube_config[0].cluster_ca_certificate : data.azurerm_kubernetes_cluster.existing[0].kube_config[0].cluster_ca_certificate)
  cluster_client_certificate = base64decode(var.cluster.create ? azurerm_kubernetes_cluster.mcd_agent[0].kube_config[0].client_certificate : data.azurerm_kubernetes_cluster.existing[0].kube_config[0].client_certificate)
  cluster_client_key         = base64decode(var.cluster.create ? azurerm_kubernetes_cluster.mcd_agent[0].kube_config[0].client_key : data.azurerm_kubernetes_cluster.existing[0].kube_config[0].client_key)
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_kubernetes_cluster" "existing" {
  count               = var.cluster.create ? 0 : 1
  name                = var.cluster.existing_cluster_name
  resource_group_name = var.cluster.existing_cluster_resource_group_name
}

data "azurerm_storage_account" "existing" {
  count               = var.storage.create_account ? 0 : 1
  name                = var.storage.existing_account_name
  resource_group_name = var.storage.existing_account_resource_group_name
}

data "azurerm_key_vault" "existing" {
  count               = var.token_secret.create_key_vault ? 0 : 1
  name                = var.token_secret.existing_key_vault_name
  resource_group_name = var.token_secret.existing_key_vault_resource_group_name
}

# -----------------------------------------------------------------------------
# Random ID
# -----------------------------------------------------------------------------

resource "random_id" "mcd_agent_id" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Resource Group (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "mcd_agent" {
  count    = var.resource_group.existing_name == null ? 1 : 0
  name     = "${local.mcd_agent_naming_prefix}-group-${random_id.mcd_agent_id.hex}"
  location = var.location
  tags     = local.default_tags
}

# -----------------------------------------------------------------------------
# VNet + Subnet (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "mcd_agent" {
  count               = var.networking.create_vnet ? 1 : 0
  name                = "${local.mcd_agent_naming_prefix}-vnet-${random_id.mcd_agent_id.hex}"
  address_space       = var.networking.vnet_address_space
  location            = local.effective_resource_group_location
  resource_group_name = local.effective_resource_group_name
  tags                = local.default_tags
}

resource "azurerm_subnet" "mcd_agent" {
  count                = var.networking.create_vnet ? 1 : 0
  name                 = "${local.mcd_agent_naming_prefix}-subnet-${random_id.mcd_agent_id.hex}"
  resource_group_name  = local.effective_resource_group_name
  virtual_network_name = azurerm_virtual_network.mcd_agent[0].name
  address_prefixes     = var.networking.subnet_address_prefixes
}

resource "azurerm_subnet" "private_endpoints" {
  count                = var.networking.create_vnet ? 1 : 0
  name                 = "${local.mcd_agent_naming_prefix}-pe-subnet-${random_id.mcd_agent_id.hex}"
  resource_group_name  = local.effective_resource_group_name
  virtual_network_name = azurerm_virtual_network.mcd_agent[0].name
  address_prefixes     = var.networking.private_endpoints_subnet_address_prefixes
}

# -----------------------------------------------------------------------------
# AKS Cluster (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "cluster" {
  count               = var.cluster.create ? 1 : 0
  name                = "${local.cluster_name}-cluster-identity"
  resource_group_name = local.effective_resource_group_name
  location            = local.effective_resource_group_location
  tags                = local.default_tags
}

resource "azurerm_role_assignment" "cluster_network_contributor" {
  count                = var.cluster.create && var.networking.create_vnet ? 1 : 0
  scope                = azurerm_virtual_network.mcd_agent[0].id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster[0].principal_id
}

resource "azurerm_kubernetes_cluster" "mcd_agent" {
  count               = var.cluster.create ? 1 : 0
  name                = local.cluster_name
  location            = local.effective_resource_group_location
  resource_group_name = local.effective_resource_group_name
  dns_prefix          = local.cluster_name
  kubernetes_version  = var.cluster.kubernetes_version

  default_node_pool {
    name            = "default"
    node_count      = var.cluster.default_node_pool.node_count
    vm_size         = var.cluster.default_node_pool.vm_size
    vnet_subnet_id  = local.effective_subnet_id
    os_disk_size_gb = 50
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster[0].id]
  }

  oidc_issuer_enabled       = var.cluster.oidc_issuer_enabled
  workload_identity_enabled = var.cluster.workload_identity_enabled

  network_profile {
    network_plugin = "azure"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  tags = local.default_tags

  depends_on = [azurerm_role_assignment.cluster_network_contributor]
}

# -----------------------------------------------------------------------------
# Storage Account + Container (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "mcd_agent" {
  count               = var.storage.create_account ? 1 : 0
  name                = "mcdagentstore${random_id.mcd_agent_id.hex}"
  resource_group_name = local.effective_resource_group_name
  location            = local.effective_resource_group_location

  account_tier                      = "Standard"
  account_replication_type          = var.storage.account_replication_type
  https_traffic_only_enabled        = true
  min_tls_version                   = var.storage.min_tls_version
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  infrastructure_encryption_enabled = true
  tags                              = local.default_tags

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  lifecycle {
    ignore_changes = [public_network_access_enabled]
  }
}

resource "azurerm_role_assignment" "deployer_storage_blob_data_contributor" {
  count                = var.storage.create_account ? 1 : 0
  scope                = azurerm_storage_account.mcd_agent[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Azure AD role assignments can take up to 60 seconds to propagate. Without this
# wait, the container creation fails with 403 because the deployer's role is not
# yet effective on the storage account data plane.
resource "time_sleep" "wait_for_deployer_storage_role" {
  count           = var.storage.create_account ? 1 : 0
  create_duration = "60s"
  depends_on      = [azurerm_role_assignment.deployer_storage_blob_data_contributor]
}

resource "azurerm_storage_container" "mcd_agent" {
  count                 = var.storage.create_account ? 1 : 0
  name                  = local.mcd_agent_store_container_name
  storage_account_name  = azurerm_storage_account.mcd_agent[0].name
  container_access_type = "private"

  depends_on = [time_sleep.wait_for_deployer_storage_role]
}

resource "azurerm_storage_management_policy" "mcd_agent" {
  count              = var.storage.create_account ? 1 : 0
  storage_account_id = azurerm_storage_account.mcd_agent[0].id

  rule {
    name    = "obj-expiration"
    enabled = true
    filters {
      blob_types   = ["blockBlob", "appendBlob"]
      prefix_match = ["${local.mcd_agent_store_container_name}/${local.mcd_agent_store_data_prefix}"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }

  rule {
    name    = "temp-expiration"
    enabled = true
    filters {
      blob_types   = ["blockBlob", "appendBlob"]
      prefix_match = ["${local.mcd_agent_store_container_name}/${local.mcd_agent_store_data_prefix}/tmp"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 2
      }
    }
  }

  rule {
    name    = "response-expiration"
    enabled = true
    filters {
      blob_types   = ["blockBlob", "appendBlob"]
      prefix_match = ["${local.mcd_agent_store_container_name}/${local.mcd_agent_store_data_prefix}/responses"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 1
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Key Vault + Secret (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "mcd_agent" {
  count               = var.token_secret.create_key_vault ? 1 : 0
  name                = "mcd-agent-${random_id.mcd_agent_id.hex}"
  location            = local.effective_resource_group_location
  resource_group_name = local.effective_resource_group_name
  tenant_id           = local.effective_tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true
  tags                      = local.default_tags
}

resource "azurerm_role_assignment" "deployer_key_vault_secrets_officer" {
  count                = var.token_secret.create_key_vault ? 1 : 0
  scope                = azurerm_key_vault.mcd_agent[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Azure AD role assignments can take up to 60 seconds to propagate. Without this
# wait, the secret creation fails with 403 because the deployer's role is not
# yet effective on the Key Vault.
resource "time_sleep" "wait_for_deployer_kv_role" {
  count           = var.token_secret.create_key_vault ? 1 : 0
  create_duration = "60s"
  depends_on      = [azurerm_role_assignment.deployer_key_vault_secrets_officer]
}

resource "azurerm_key_vault_secret" "mcd_agent_token" {
  count        = var.token_secret.create_key_vault ? 1 : 0
  name         = var.token_secret.name
  value        = jsonencode({ "mcd_id" = coalesce(var.token_credentials.mcd_id, ""), "mcd_token" = coalesce(var.token_credentials.mcd_token, "") })
  key_vault_id = azurerm_key_vault.mcd_agent[0].id

  depends_on = [time_sleep.wait_for_deployer_kv_role]

  lifecycle {
    ignore_changes = [value]

    precondition {
      condition     = var.token_credentials.mcd_id != null && var.token_credentials.mcd_token != null
      error_message = "Both mcd_id and mcd_token are required in token_credentials when token_secret.create_key_vault is true."
    }
  }
}

# -----------------------------------------------------------------------------
# User Assigned Managed Identity + Federated Credential
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "mcd_agent" {
  name                = "${local.mcd_agent_naming_prefix}-identity-${random_id.mcd_agent_id.hex}"
  resource_group_name = local.effective_resource_group_name
  location            = local.effective_resource_group_location
  tags                = local.default_tags
}

resource "azurerm_federated_identity_credential" "mcd_agent" {
  name                = "kubernetes-federated-credential"
  resource_group_name = local.effective_resource_group_name
  parent_id           = azurerm_user_assigned_identity.mcd_agent.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = local.effective_aks_oidc_issuer_url
  subject             = "system:serviceaccount:${local.namespace}:${local.service_account_name}"
}

# -----------------------------------------------------------------------------
# Role Assignments
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "mcd_agent_storage_blob_contributor" {
  scope                = local.effective_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.mcd_agent.principal_id
}

resource "azurerm_role_assignment" "mcd_agent_key_vault_secrets_user" {
  scope                = local.effective_key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.mcd_agent.principal_id
}

# -----------------------------------------------------------------------------
# Helm - External Secrets Operator (conditional)
# -----------------------------------------------------------------------------

resource "helm_release" "external_secrets" {
  count            = var.helm.install_external_secrets_operator ? 1 : 0
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true

  depends_on = [azurerm_kubernetes_cluster.mcd_agent]
}

# -----------------------------------------------------------------------------
# Helm - Agent (conditional)
# -----------------------------------------------------------------------------

resource "kubernetes_namespace_v1" "mcd_agent" {
  count = var.helm.deploy_agent ? 1 : 0

  metadata {
    name = local.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }

    annotations = {
      "meta.helm.sh/release-name"      = "mcd-agent"
      "meta.helm.sh/release-namespace" = local.namespace
    }
  }

  depends_on = [azurerm_kubernetes_cluster.mcd_agent]
}

resource "helm_release" "mcd_agent" {
  count            = var.helm.deploy_agent ? 1 : 0
  name             = "mcd-agent"
  repository       = var.helm.chart_repository
  chart            = var.helm.chart_name
  version          = var.helm.chart_version
  namespace        = local.namespace
  create_namespace = false

  values = [local.helm_values_yaml]

  depends_on = [
    azurerm_kubernetes_cluster.mcd_agent,
    helm_release.external_secrets,
    kubernetes_namespace_v1.mcd_agent,
    azurerm_federated_identity_credential.mcd_agent,
    azurerm_role_assignment.mcd_agent_storage_blob_contributor,
    azurerm_role_assignment.mcd_agent_key_vault_secrets_user,
  ]
}

locals {
  base_helm_values = {
    namespace    = local.namespace
    replicaCount = var.agent.replica_count

    image = {
      repository = split(":", var.agent.image)[0]
      pullPolicy = var.agent.pull_policy
      tag        = length(split(":", var.agent.image)) > 1 ? split(":", var.agent.image)[1] : "latest-generic"
    }

    container = {
      backendServiceUrl  = var.backend_service_url
      storageAccountName = local.effective_storage_account_name
      storageBucketName  = local.effective_storage_container_name
      storageType        = "AZURE_BLOB"
    }

    service = {
      annotations = var.helm.service_annotations
    }

    serviceAccount = {
      annotations = {
        "azure.workload.identity/client-id" = azurerm_user_assigned_identity.mcd_agent.client_id
      }
    }

    deploymentTemplateLabels = {
      "azure.workload.identity/use" = "true"
    }

    secretStore = {
      provider = {
        azurekv = {
          tenantId = local.effective_tenant_id
          authType = "WorkloadIdentity"
          vaultUrl = local.effective_key_vault_url
          serviceAccountRef = {
            name      = local.service_account_name
            namespace = local.namespace
          }
        }
      }
    }

    tokenSecret = {
      remoteRef = {
        key = var.token_secret.name
      }
    }

    integrationsSecrets = {
      data = [for s in var.integration_secrets : {
        secretKey = s.secret_key
        remoteRef = {
          key = s.remote_ref_key
        }
      }]
    }

    logsCollector    = { enabled = var.helm.enabled_logs_collector }
    metricsCollector = { enabled = var.helm.enabled_metrics_collector }
  }

  helm_values = merge(local.base_helm_values, var.custom_values, {
    logsCollector = merge(
      try(var.custom_values.logsCollector, {}),
      { enabled = var.helm.enabled_logs_collector }
    )
    metricsCollector = merge(
      try(var.custom_values.metricsCollector, {}),
      { enabled = var.helm.enabled_metrics_collector }
    )
  })

  helm_values_yaml = yamlencode(local.helm_values)
}
