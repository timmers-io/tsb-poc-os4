# Generate certificates 
Be sure to change into the pki folder to run these commands.  You can remove the new_certificates folder to start clean as neeeded.

## These commands use "example.com" as the domain
The name we will use for the custom ca is  "cluster.example.com"

```bash
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout new_certificates/example.com.key -out new_certificates/example.com.crt
```

```bash
openssl req -out new_certificates/cluster.example.com.csr -newkey rsa:2048 -nodes -keyout new_certificates/cluster.example.com.key -subj "/CN=cluster.example.com/O=example organization"
```

```bash
openssl x509 -req -sha256 -days 365 -CA new_certificates/example.com.crt -CAkey new_certificates/example.com.key -set_serial 0 -in new_certificates/cluster.example.com.csr -out new_certificates/cluster.example.com.crt
```

## Next follow the instuctions for onboarding clusters with istio-csr
> Make sure you are pointing to the correct kubernetes cluster context

> Create these certificates once and apply to all the control plane clusters you want to have with the same chain of trust

Delete the secret if it already exists - update the namespace as appropriate

```bash
kubectl -n istio-system delete secret custom-ca-example-com
```

```bash
kubectl create secret generic custom-ca-example-com -n istio-system \
      --from-file=new_certificates/cluster.example.com.crt \
      --from-file=new_certificates/cluster.example.com.key \
      --from-file=new_certificates/example.com.crt

```

