# Existing VNet Example

Deploys a new AKS cluster and Monte Carlo agent into an existing Virtual Network.

You must provide the full Azure resource ID of an existing subnet. The subnet should have outbound internet access for pulling container images and reaching the Monte Carlo backend.

## Usage

```bash
terraform init
terraform apply -var="location=East US"
```
