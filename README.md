# tsb-poc-os4
Tetrate Service Bridge (TSB) on OpenShift 4

## Requirements
- OCP 4.x
- Kubernetes 1.21.x
- cert-manager 1.7.2 csr 0.4 
- Elasticsearch 7.15.2
- TSB 1.4.7

## Steps to prepare the Management Plane cluster 
We will be using the included default demo installations for PostgreSQL and LDAP for this Proof of Concept (POC) installation.

We will install cert-manager and Elasticsearch on the management plane cluster before installing TSB.

TSB proof of concept files

| Steps                                | Description |
| :---                                 | ----        |
| [cert-manager](/cert-manager.md)     | Install cert-manager and create certificates |
| [Elasticsearch](/elastic.md)         | Install the Elasticsearch operator and create the Elasticsearch instance |
| [tsb-mp](/tsb-mp.md)                 | TSB Management Plane installation |
| [app-cluster01](/app-cluster01.md)   | Onboarding the mp cluster as an application cluster |
| [app-cluster02](/app-cluster02.md)   | Onboarding an additional OpenShift cluster |
| [app-cluster03](/app-cluster03.md)   | Onboarding an EKS cluster |
| [bookinfo](/bookinfo.md)             | Deploying bookinfo |
| [tsb-config](/tsb-config.md)         | Creating TSB Tenants, Workspaces, and Groups |
| use-cases                            | Implementing Use Cases |

