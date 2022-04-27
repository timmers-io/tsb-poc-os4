# tsb-poc-os4
Tetrate Service Bridge (TSB) on OpenShift 4

## Steps to prepare the Management Plane cluster for this Proof of Concept (POC) installation 
We will be using the included default demo installations for PostgreSQL and LDAP.

We will install cert-manager and Elasticsearch before installing TSB.
- Install cert-manager
- Create certificates
- Install the Elasticsearch operator
- Create the Elasticsearch instance
- Begin the TSB Management Plane installation
