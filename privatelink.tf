# -----------------------------------------------------------------------------
# Azure Private Link (conditional)
# -----------------------------------------------------------------------------

locals {
  # Extract hostname from backend_service_url (e.g. "https://artemis.privatelink.getmontecarlo.com" -> "artemis.privatelink.getmontecarlo.com")
  private_link_hostname = var.private_link != null ? regex("https?://([^/:]+)", var.backend_service_url)[0] : null
}

resource "azurerm_private_endpoint" "monte_carlo" {
  count               = var.private_link != null ? 1 : 0
  name                = "${local.mcd_agent_naming_prefix}-mc-pe-${random_id.mcd_agent_id.hex}"
  resource_group_name = local.effective_resource_group_name
  location            = local.effective_resource_group_location
  subnet_id           = local.effective_private_endpoints_subnet_id
  tags                = local.default_tags

  private_service_connection {
    name                           = "${local.mcd_agent_naming_prefix}-mc-psc-${random_id.mcd_agent_id.hex}"
    private_connection_resource_id = var.private_link.private_link_service_resource_id
    subresource_names              = var.private_link.subresource_names
    is_manual_connection           = true
    request_message                = "Monte Carlo agent private link connection"
  }

  lifecycle {
    precondition {
      condition     = can(regex("\\.privatelink\\.", var.backend_service_url))
      error_message = "When private_link is configured, backend_service_url must contain '.privatelink.' (e.g. https://artemis.privatelink.getmontecarlo.com)."
    }

    precondition {
      condition     = local.effective_vnet_id != null
      error_message = "A VNet is required for private link. Either set networking.create_vnet = true or provide networking.existing_vnet_id."
    }

  }
}

resource "azurerm_private_dns_zone" "monte_carlo" {
  count               = var.private_link != null ? 1 : 0
  name                = local.private_link_hostname
  resource_group_name = local.effective_resource_group_name
  tags                = local.default_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "monte_carlo" {
  count                 = var.private_link != null ? 1 : 0
  name                  = "${local.mcd_agent_naming_prefix}-mc-dns-link-${random_id.mcd_agent_id.hex}"
  resource_group_name   = local.effective_resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.monte_carlo[0].name
  virtual_network_id    = local.effective_vnet_id
  registration_enabled  = false
  tags                  = local.default_tags
}

resource "azurerm_private_dns_a_record" "monte_carlo" {
  count               = var.private_link != null ? 1 : 0
  name                = "@"
  zone_name           = azurerm_private_dns_zone.monte_carlo[0].name
  resource_group_name = local.effective_resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.monte_carlo[0].private_service_connection[0].private_ip_address]
}
