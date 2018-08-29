# Before you start aka prerequisites
1. Have installed
    1. bbl CLI
    1. Bosh CLI
    1. git CLI
    1. gcloud CLI
    1. kubectl CLI
1. Have a GCP account



# General Instructions
1. Deploy Bosh
2. Deploy CFCR cluster
3. Setup kubectl to talk to your cluster
4. Deploy a workload using kubectl

# Deploying BOSH


# Known issues
1. This script will always deploy the latest CFCR release


-------------------------------------

### Proxy

| Name | Purpose | Notes |
|:---  |:---     |:---   |
| [`ops-files/add-proxy.yml`](ops-files/add-proxy.yml) | Configure HTTP_PROXY, HTTPS_PROXY, and NO_PROXY for Kubernetes components | All Kubernetes components are configured with the `http_proxy`, `https_proxy`, and `no_proxy` environment variables |

### Kubernetes

| Name | Purpose | Notes |
|:---  |:---     |:---   |
| [`ops-files/addons-spec.yml`](ops-files/addons-spec.yml) | Addons to be deployed into the Kubernetes cluster | - |
| [`ops-files/allow-privileged-containers.yml`](ops-files/allow-privileged-containers.yml) | Allows privileged containers for the Kubernetes cluster | - |
| [`ops-files/disable-anonymous-auth.yml`](ops-files/disable-anonymous-auth.yml) | Disable `anonymous-auth` on the API server | - |
| [`ops-files/disable-deny-escalating-exec.yml`](ops-files/disable-deny-escalating-exec.yml) | Disable `DenyEscalatingExec` in API server admission control | - |
| [`ops-files/add-oidc-endpoint.yml`](ops-files/add-oidc-endpoint.yml) | Enable OIDC authentication for the Kubernetes cluster | - |
| [`ops-files/use-separate-master-ca.yml`](ops-files/use-separate-master-ca.yml) | Configure master to use a different CA | *This is currently an experimental ops-file.* This may not work with all Certificate Signing Requests. |

### Dev

| Name | Purpose | Notes |
|:---  |:---     |:---   |
| [`ops-files/kubo-local-release.yml`](ops-files/kubo-local-release.yml) | Deploy a local kubo release located in `../kubo-release` | -  |


