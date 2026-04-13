# MCD On-Prem Agent - Existing Cluster Example

This example deploys the Monte Carlo on-prem agent on an existing AKS cluster.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.3
- An existing AKS cluster with kubectl access and OIDC issuer enabled
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) configured with appropriate credentials

## Usage

Update `main.tf` with your existing cluster name, resource group, and region, then:

```bash
terraform init
terraform apply
```
