# NOTE: The azurerm provider is intentionally NOT configured here. Reusable modules
# should not include provider configuration blocks — the calling root module must
# configure the azurerm provider. See README for required provider settings.
#
# The helm and kubernetes providers are configured here because they depend on the
# cluster's kubeconfig, which is only available after the cluster is created/read.
# This is a known compromise for Kubernetes-deploying modules.

provider "helm" {
  kubernetes = {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    client_certificate     = local.cluster_client_certificate
    client_key             = local.cluster_client_key
  }
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  client_certificate     = local.cluster_client_certificate
  client_key             = local.cluster_client_key
}
