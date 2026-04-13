# MCD On-Prem Agent - Full Deployment Example

This example deploys the Monte Carlo on-prem agent on a new AKS cluster with all infrastructure provisioned automatically.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.3
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Usage

```bash
cp credentials.tfvars.example credentials.tfvars
# Edit credentials.tfvars with your Monte Carlo mcd_id and mcd_token

terraform init
terraform apply -var-file=credentials.tfvars
```

## After Deployment

2. Configure kubectl:
   ```bash
   az aks get-credentials --name $(terraform output -raw cluster_name) --resource-group $(terraform output -raw resource_group_name)
   ```
