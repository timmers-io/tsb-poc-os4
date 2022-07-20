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

tctl version --local-only

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

## Next, create the management plane yaml depending on your load balancer type

From the documentation: https://docs.tetrate.io/service-bridge/1.4.x/en-us/knowledge_base/faq#configure-aws-internal-elbs

### If using AWS internal load balancers, use this version of the configuration

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
    frontEnvoy:
      kubeSpec:
        service:
          annotations:
            service.beta.kubernetes.io/aws-load-balancer-scheme: internal
    xcp:
      centralAuthModes:
        jwt: true
        mutualTls: false
EOF

```

### If using AWS external load balancers, use this version of the configuration

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



Before applying it, bear in mind that you will have to allow the service accounts of the different management plane components to your OpenShift Authorization Policies.
```bash
oc adm policy add-scc-to-user anyuid -n tsb -z tsb-iam
oc adm policy add-scc-to-user anyuid -n tsb -z tsb-oap
oc adm policy add-scc-to-user anyuid -n tsb -z default
oc adm policy add-scc-to-user anyuid -n tsb -z tsb-zipkin
oc adm policy add-scc-to-user privileged -n tsb -z tsb-zipkin

```


```bash
oc apply -f ${FOLDER}/managementplane.yaml

```

You can monitor the progress of the pods starting up:
```bash
oc get po -n tsb -w

```
> This could take 3-5 minutes
```console
NAME                                            READY   STATUS              RESTARTS   AGE
envoy-866cb587cd-2xk4p                          1/1     Running             0          25s
envoy-866cb587cd-mhgbz                          1/1     Running             0          25s
iam-5cdcbd754-c7dmb                             0/1     Init:0/6            0          21s
ldap-69f8665fc8-bjvbw                           1/1     Running             0          21s
mpc-5c7fbdfc6f-8hxrs                            0/1     ContainerCreating   0          21s
oap-864784847c-9x5f7                            0/1     Init:0/2            0          21s
otel-collector-5c58db5998-vrl4m                 1/1     Running             0          25s
postgres-d86ccf878-cktg7                        0/1     ContainerCreating   0          21s
tsb-7f7cd9cf7c-7c8rp                            0/1     Init:0/2            0          25s
tsb-operator-management-plane-55b84b5fd-4lflf   1/1     Running             0          4m4s
web-59f59c9dcd-48v54                            0/1     CrashLoopBackOff    1          21s
xcp-operator-central-57fbd977bf-4lq9r           1/1     Running             0          21s
zipkin-6bdf758584-ntc55                         0/1     Init:2/3            0          21s
```

After the pods are all running, we need to make sure the teamsync runs before logging in for the first time.
```bash
oc create job -n tsb teamsync-bootstrap --from=cronjob/teamsync

```

After the teamsync job completes, test the connection:
```bash
export TCTL_CONFIG=./files/tctl-config.yaml

tctl config clusters set default --bridge-address $TSB_FQDN:8443

# if self-signed cert in use
tctl config clusters set default --tls-insecure

tctl config view

```

### NOTE: we now need to update DNS to point to the LoadBalancer service created for envoy
Check the EXTERNAL-IP from the envoy service - use this to create/update the DNS record for the $TSB_FQDN we have configured

```bash
oc get svc -n tsb envoy

```

### After DNS is configured and propagated, you can test the service by logging in:

Login with the CLI
```bash
tctl login --org tetrate --tenant tetrate --username admin --password Tetrate123

```

Open in a browser
```bash
tctl ui

```
