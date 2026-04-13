# -----------------------------------------------------------------------------
# Storage Account Private Endpoint (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "storage" {
  count               = var.storage.create_account ? 1 : 0
  name                = "${local.mcd_agent_naming_prefix}-storage-pe-${random_id.mcd_agent_id.hex}"
  resource_group_name = local.effective_resource_group_name
  location            = local.effective_resource_group_location
  subnet_id           = local.effective_private_endpoints_subnet_id
  tags                = local.default_tags

  private_service_connection {
    name                           = "${local.mcd_agent_naming_prefix}-storage-psc-${random_id.mcd_agent_id.hex}"
    private_connection_resource_id = azurerm_storage_account.mcd_agent[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob[0].id]
  }

  lifecycle {
    precondition {
      condition     = local.effective_private_endpoints_subnet_id != null
      error_message = "A private endpoints subnet is required when creating a storage account. Either set networking.create_vnet = true or provide networking.existing_private_endpoints_subnet_id."
    }

    precondition {
      condition     = local.effective_vnet_id != null
      error_message = "A VNet is required for private endpoints. Either set networking.create_vnet = true or provide networking.existing_vnet_id."
    }
  }
}

resource "azurerm_private_dns_zone" "storage_blob" {
  count               = var.storage.create_account ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.effective_resource_group_name
  tags                = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  count                 = var.storage.create_account ? 1 : 0
  name                  = "${local.mcd_agent_naming_prefix}-storage-dns-link-${random_id.mcd_agent_id.hex}"
  resource_group_name   = local.effective_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob[0].name
  virtual_network_id    = local.effective_vnet_id
  registration_enabled  = false
  tags                  = local.default_tags
}

# -----------------------------------------------------------------------------
# Key Vault Private Endpoint (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "key_vault" {
  count               = var.token_secret.create_key_vault ? 1 : 0
  name                = "${local.mcd_agent_naming_prefix}-kv-pe-${random_id.mcd_agent_id.hex}"
  resource_group_name = local.effective_resource_group_name
  location            = local.effective_resource_group_location
  subnet_id           = local.effective_private_endpoints_subnet_id
  tags                = local.default_tags

  private_service_connection {
    name                           = "${local.mcd_agent_naming_prefix}-kv-psc-${random_id.mcd_agent_id.hex}"
    private_connection_resource_id = azurerm_key_vault.mcd_agent[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "vault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
  }

  lifecycle {
    precondition {
      condition     = local.effective_private_endpoints_subnet_id != null
      error_message = "A private endpoints subnet is required when creating a key vault. Either set networking.create_vnet = true or provide networking.existing_private_endpoints_subnet_id."
    }

    precondition {
      condition     = local.effective_vnet_id != null
      error_message = "A VNet is required for private endpoints. Either set networking.create_vnet = true or provide networking.existing_vnet_id."
    }
  }
}

resource "azurerm_private_dns_zone" "key_vault" {
  count               = var.token_secret.create_key_vault ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.effective_resource_group_name
  tags                = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count                 = var.token_secret.create_key_vault ? 1 : 0
  name                  = "${local.mcd_agent_naming_prefix}-kv-dns-link-${random_id.mcd_agent_id.hex}"
  resource_group_name   = local.effective_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = local.effective_vnet_id
  registration_enabled  = false
  tags                  = local.default_tags
}
