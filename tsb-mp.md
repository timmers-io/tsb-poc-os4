# Install and verify the TSB Management Plane

## Management plane cluster

### Install TSB Management Plane


From the root folder of this project, set these enviroment variables
```bash
export FOLDER='./files'
export TSB_FQDN="<insert your FQDN here>"
export REGISTRY=<insert your registry here>

```

Export and confirm we can get the Elasticsearch CA certificate
```bash
export ES_CACERT=`oc get secret elasticsearch-es-http-ca-internal -n es -o json | jq -r '.data."tls.crt"' | base64 -d | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}'`

echo $ES_CACERT

```

Verify the certificates are created in the tsb namespace

```bash
oc get certificates -n tsb
oc get secrets -n tsb | grep tls

```

Should look something like this:
```console
$ oc get certificates -n tsb
NAME                  READY   SECRET                AGE
mpc-certs             True    mpc-certs             45h
tsb-certs             True    tsb-certs             45h
xcp-central-cert      True    xcp-central-cert      45h
xcp-identity-issuer   True    xcp-identity-issuer   45h
```

```console
$ oc get secrets -n tsb | grep tls
mpc-certs                                       kubernetes.io/tls                     3      45h
tsb-certs                                       kubernetes.io/tls                     3      45h
xcp-central-cert                                kubernetes.io/tls                     3      45h
xcp-identity-issuer                             kubernetes.io/tls                     3      45h
```



