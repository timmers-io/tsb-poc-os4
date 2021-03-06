# Generate certificates 
You can remove the new_certificates folder to start clean as neeeded.

## These commands use "example.com" as the domain
The name we will use for the custom ca is  "example.com"

## Do NOT recreate these if you are already using them in clusters - we want the clusters to have the same chain of trust!

```bash
openssl req -x509 -sha256 -nodes -days 365 -extensions v3_ca -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout pki/new_certificates/example.com.key -out pki/new_certificates/example.com.crt
```

## Next follow the instuctions for onboarding clusters with istio-csr
> Make sure you are pointing to the correct kubernetes cluster context

> Create this certificate once and apply to all the control plane clusters you want to have with the same chain of trust

Create the istio-system namespace if it is not already there
```bash
# We need this namespace to exist since our cert will be placed there
kubectl create namespace istio-system

```

Delete the secret if it already exists - update the namespace as appropriate

```bash
kubectl -n istio-system delete secret custom-ca-example-com
```

```bash
kubectl create -n istio-system secret generic custom-ca-example-com \
  --from-file=tls.crt=pki/new_certificates/example.com.crt \
  --from-file=tls.key=pki/new_certificates/example.com.key

```

> NOTE: I needed to add this to my mac openssl config: /etc/ssl/openssl.cnf to generate a cert that is a CA.  Without this I saw the error "Error getting keypair for CA issuer: certificate is not a CA"

```console
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
```
## Nice getting started guide here
https://github.com/cert-manager/istio-csr/blob/main/docs/getting_started.md

