# MCD On-Prem Agent - Full Deployment Example

This example deploys the Monte Carlo on-prem agent on a new AKS cluster with all infrastructure provisioned automatically.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.3
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Usage

```bash
terraform init
terraform apply
```

## After Deployment

1. Update the agent token secret in Azure Key Vault with your Monte Carlo credentials:
   ```bash
   az keyvault secret set --vault-name $(terraform output -raw key_vault_url | sed 's|https://||;s|\.vault\.azure\.net.*||') \
     --name mcd-agent-token \
     --value '{"mcd_id":"YOUR_MCD_ID","mcd_token":"YOUR_MCD_TOKEN"}'
   ```

2. Configure kubectl:
   ```bash
   az aks get-credentials --name $(terraform output -raw cluster_name) --resource-group $(terraform output -raw resource_group_name)
   ```
