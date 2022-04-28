# tsb-poc-os4
Tetrate Service Bridge (TSB) on OpenShift 4

## Steps to prepare the Management Plane cluster for this Proof of Concept (POC) installation 
We will be using the included default demo installations for PostgreSQL and LDAP.

We will install cert-manager and Elasticsearch before installing TSB.
- Install cert-manager and create certificates [cert-manager](/cert-manager.md)  
- Install the Elasticsearch operator and create the Elasticsearch instance
- Begin the TSB Management Plane installation
