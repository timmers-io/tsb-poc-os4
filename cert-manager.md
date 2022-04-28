# Install and verify cert-manager

## Management plane cluster

### Install cert-manager

Install cert-manager v1.7.2
```bash
oc apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.2/cert-manager.yaml

```


From the root folder of this project, set these enviroment variables
```bash
export FOLDER='./files'
export TSB_FQDN="tiaa-alpha.cx.tetrate.info"

```

Create the tsb namespace
```bash
oc create ns tsb

```

Create the cert-manager configuration - note the dnsNames in the xcp-central-cert.  Refer to the documentation for a complete description of the certificate requirements.

https://docs.tetrate.io/service-bridge/1.4.x/en-us/setup/on_prem/certificate-requirements

```bash
cat >"${FOLDER}/tsb-certs-infra-cert-manager.yaml" <<EOF
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: xcp-trust-anchor
  namespace: tsb
spec:
  selfSigned: {}
---
# to create root CA
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: xcp-identity-issuer
  namespace: tsb
spec:
  secretName: xcp-identity-issuer
  issuerRef:
    name: xcp-trust-anchor
    kind: Issuer
  duration: 30000h
  isCA: true
  commonName: ca.xcp.tetrate.io
  uris:
    - spiffe://xcp.tetrate.io/ca
  usages:
    - cert sign
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: xcp-identity-issuer
  namespace: tsb
spec:
  ca:
    secretName: xcp-identity-issuer
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: xcp-central-cert
  namespace: tsb
spec:
  secretName: xcp-central-cert
  issuerRef:
    name: xcp-identity-issuer
    kind: Issuer
  duration: 30000h
  isCA: false
  dnsNames:
    - "$TSB_FQDN"   
    - "central.xcp.tetrate.io"
  uris:
    - spiffe://xcp.tetrate.io/central
  usages:
    - server auth
    - client auth
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: mpc-certs
  namespace: tsb
spec:
  secretName: mpc-certs
  issuerRef:
    name: xcp-identity-issuer
    kind: Issuer
  duration: 30000h
  isCA: false
  dnsNames:
    - "mpc.tsb.svc.cluster.local"
  uris:
    - spiffe://xcp.tetrate.io/mpc
  usages:
    - client auth
    - server auth
EOF
```

Apply the generated configuration:
```bash
oc apply -f "${FOLDER}/tsb-certs-infra-cert-manager.yaml"

```

### Verify the certificates are created in the tsb namespace


