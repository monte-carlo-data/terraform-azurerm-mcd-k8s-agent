# Monte Carlo Agent - Azure AKS Module

This module deploys the [Monte Carlo](https://www.montecarlodata.com/) containerized agent on Azure using AKS (Azure Kubernetes Service). Storage and Key Vault resources are automatically secured with private endpoints when created by the module.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.3
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) with [authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for cluster access
- A Monte Carlo account with agent credentials (mcd_id and mcd_token)

## Required Azure Permissions

The identity running Terraform (your user or service principal) needs the following roles on the target subscription or resource group:

| Role | Purpose | Required When |
|---|---|---|
| **Contributor** | Create resource groups, AKS clusters, storage accounts, Key Vaults, VNets | Always (for full deployment) |
| **User Access Administrator** or **Owner** | Create role assignments for Key Vault and Storage access (see below) | Always |

### Role Assignments Created by This Module

This module creates the following role assignments, which require `Microsoft.Authorization/roleAssignments/write` permission:

| Role Assigned | Assignee | Scope | Purpose |
|---|---|---|---|
| **Key Vault Secrets Officer** | Terraform deployer | Key Vault | Allow Terraform to create the initial agent token secret |
| **Key Vault Secrets User** | Managed Identity | Key Vault | Allow the agent to read secrets at runtime |
| **Storage Blob Data Contributor** | Managed Identity | Storage Account | Allow the agent to read/write blob data |

> **Note:** If your identity has the **"Role Based Access Control Administrator"** role instead of **"Owner"** or **"User Access Administrator"**, its ABAC condition must allow assigning the roles listed above. Otherwise, Terraform will fail with a `403 AuthorizationFailed` error.

> **Tip:** If you cannot obtain the required role assignment permissions, you can pre-create the Key Vault and storage account with their role assignments outside of Terraform and use the `existing_*` variables to reference them.

## Usage

### Full deployment (new cluster)

```hcl
module "mcd_agent" {
  source = "monte-carlo-data/mcd-agent-k8s/azurerm"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"
  helm                = { chart_version = "0.0.2" }
}
```

### Existing VNet

```hcl
module "mcd_agent" {
  source = "monte-carlo-data/mcd-agent-k8s/azurerm"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"
  helm                = { chart_version = "0.0.2" }

  networking = {
    create_vnet                          = false
    existing_subnet_id                   = "/subscriptions/.../subnets/aks-subnet"
    existing_vnet_id                     = "/subscriptions/.../virtualNetworks/my-vnet"
    existing_private_endpoints_subnet_id = "/subscriptions/.../subnets/pe-subnet"
  }
}
```

### Existing cluster

```hcl
module "mcd_agent" {
  source = "monte-carlo-data/mcd-agent-k8s/azurerm"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"
  helm                = { chart_version = "0.0.2" }

  cluster = {
    create                               = false
    existing_cluster_name                = "my-cluster"
    existing_cluster_resource_group_name = "my-rg"
  }
  networking = {
    create_vnet                          = false
    existing_subnet_id                   = "/subscriptions/.../subnets/aks-subnet"
    existing_vnet_id                     = "/subscriptions/.../virtualNetworks/my-vnet"
    existing_private_endpoints_subnet_id = "/subscriptions/.../subnets/pe-subnet"
  }
}
```

### Private Link

```hcl
module "mcd_agent" {
  source = "monte-carlo-data/mcd-agent-k8s/azurerm"

  location            = "East US"
  backend_service_url = "https://artemis.privatelink.getmontecarlo.com"
  helm                = { chart_version = "0.0.2" }

  private_link = {
    private_link_service_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mc-rg/providers/Microsoft.Network/privateLinkServices/mc-pls"
  }
}
```

### Infrastructure only (manual Helm deployment)

```hcl
module "mcd_agent" {
  source = "monte-carlo-data/mcd-agent-k8s/azurerm"

  location            = "East US"
  backend_service_url = "https://your-instance.getmontecarlo.com"
  helm                = { chart_version = "0.0.2", deploy_agent = false }
}

output "helm_values" {
  value     = module.mcd_agent.helm_values
  sensitive = true
}
```

## Agent Token Configuration

Provide your Monte Carlo agent credentials via the `token_credentials` variable:

```hcl
token_credentials = {
  mcd_id    = "YOUR_MCD_ID"
  mcd_token = "YOUR_MCD_TOKEN"
}
```

These are written to Key Vault on initial deployment. Subsequent `terraform apply` runs will not overwrite the secret value, so manual updates via `az keyvault secret set` are preserved.

Alternatively, use an existing Key Vault with the token pre-populated via the `token_secret.existing_*` variables.

## After Deployment

Configure kubectl access:
```bash
az aks get-credentials --name <cluster_name> --resource-group <resource_group_name>
```

## Outputs

| Name | Description |
|------|-------------|
| resource_group_name | Resource group name |
| cluster_name | AKS cluster name |
| cluster_endpoint | Endpoint for AKS control plane |
| storage_account_name | Storage account name for agent data |
| storage_container_name | Storage container name for agent data |
| key_vault_url | Key Vault URL for agent secrets |
| managed_identity_client_id | Client ID of the managed identity |
| managed_identity_principal_id | Principal ID of the managed identity |
| namespace | Kubernetes namespace for the agent |
| private_endpoint_id | ID of the Monte Carlo Private Link endpoint |
| private_endpoint_ip | Private IP address of the Monte Carlo Private Link endpoint |
| helm_values | Helm values for manual deployment |

## Releases and Development

This module follows [standard module structure](https://www.terraform.io/docs/modules/index.html). Run `terraform fmt` before committing.

CircleCI runs `make sanity-check` on every PR.

To release a new version, create and push a new tag: `git tag v0.0.1 && git push origin v0.0.1`

## License

See [LICENSE](LICENSE).

## Security

See [SECURITY](SECURITY.md).
