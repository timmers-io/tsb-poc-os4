# Install and verify the TSB Management Plane

## Management plane cluster

### Install TSB Management Plane


From the root folder of this project, set these enviroment variables.
```bash
export FOLDER='./files'
export TSB_FQDN="tsb.example.tetrate.com"
export REGISTRY=us-central1-docker.pkg.dev/example/tsb-147

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

Make sure that oc version matches with the cluster version
```bash
oc version

```

Verify the tctl version is 1.4.7
```bash
export TCTL_CONFIG=./files/tctl-config.yaml

tctl version

```

In OpenShift, the TSB operator needs the anyuid SCC in order to be able to start the webhooks for validating and setting defaults to the ManagementPlane resources.
```bash
oc adm policy add-scc-to-user anyuid \
    system:serviceaccount:tsb:tsb-operator-management-plane

```
### Operator Installation
First, create the manifest allowing you to install the management plane operator from your private registry:

```bash
tctl install manifest management-plane-operator \
  --registry $REGISTRY > ${FOLDER}/managementplaneoperator.yaml

```

The managementplaneoperator.yaml file created by the install manifest command can be applied directly to the appropriate cluster by using the oc client:
```bash
oc apply -f ${FOLDER}/managementplaneoperator.yaml

```
After applying the manifest you will see the operator running in the tsb namespace:
```bash
oc get pod -n tsb

```

Example output:
```console
$ oc get pod -n tsb
NAME                                            READY   STATUS      RESTARTS   AGE
tsb-operator-management-plane-55b84b5fd-h2rjf   1/1     Running     0          46h
```

The management plane components need some secrets for external communication purposes. The required secrets are split into five categories represented by the flag’s prefix: tsb, xcp, postgres, elastic and ldap.

These can be generated in the correct format by passing them as command-line flags to the management-plane manifest command.

```bash
tctl install manifest management-plane-secrets \
    --allow-defaults \
    --tsb-admin-password "Tetrate123" \
    --elastic-password=`oc get secret -n es elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 -d` \
    --elastic-username elastic \
    --elastic-ca-certificate="$ES_CACERT" > ${FOLDER}/management-plane-secrets.yaml

```

```bash
oc apply -f ${FOLDER}/management-plane-secrets.yaml

```

tsb cert

```bash
cat >"${FOLDER}/tsb-certs-certificate.yaml" <<EOF
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tsb-certs
  namespace: tsb
spec:
  secretName: tsb-certs
  issuerRef:
    name: xcp-trust-anchor
    kind: Issuer
  dnsNames:
  - "$TSB_FQDN"
EOF

```

```bash
oc apply -f "${FOLDER}/tsb-certs-certificate.yaml"

```

### Now we’re ready to deploy the management plane.

To deploy the management plane we need to create a ManagementPlane custom resource in the Kubernetes cluster that describes the management plane.

```bash
export ES_HOST=`oc get svc -n es elasticsearch-es-http -o json | jq -r '.status.loadBalancer.ingress[0].hostname'`
echo $ES_HOST

```

```bash
cat >"${FOLDER}/managementplane.yaml" <<EOF
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  hub: $REGISTRY
  organization: tetrate
  telemetryStore:
    elastic:
      host: $ES_HOST
      port: 9200
      version: 7
      selfSigned: true
      protocol: https
  components:
    xcp:
      centralAuthModes:
        jwt: true
        mutualTls: false
EOF

```

```bash
oc apply -f ${FOLDER}/managementplane.yaml

```

