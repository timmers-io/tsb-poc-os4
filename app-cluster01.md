# Install Istio 

## Management plane cluster

### Install Istio on the mp cluster
This management plane cluster will be doing double duty acting as the TSB MP and an application cluster CP

From the root folder of this project, set these enviroment variables.
```bash
export FOLDER='./files'
export TSB_FQDN="tsb.example.tetrate.com"
export REGISTRY=us-central1-docker.pkg.dev/example/tsb-147
export CLUSTER_NAME="app-cluster01"

```

Login, then we will apply the cluster configuration
```bash
tctl login --org tetrate --tenant tetrate --username admin --password Tetrate123

tctl get org

```

```bash
cat >"${FOLDER}/${CLUSTER_NAME}-cp.yaml" <<EOF
---
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: $CLUSTER_NAME
  organization: tetrate
spec:
  tokenTtl: "8760h"
  tier1Cluster: false
  network: global
  locality:
    region: us-east-1
EOF

```

```bash
tctl apply -f "${FOLDER}/${CLUSTER_NAME}-cp.yaml"

tctl get cluster

```

### Deploy Operators
Next, you need to install the necessary components in the cluster to onboard and connect it to the management plane.

There are two operators you must deploy. First, the control plane operator, which is responsible for managing Istio, SkyWalking, Zipkin and various other components. Second, the data plane operator, which is responsible for managing gateways.

```bash
tctl install manifest cluster-operators --registry $REGISTRY  > ${FOLDER}/clusteroperators.yaml

```

Similarly to what the management plane operator requires, we need to add the anyuid SCC to the control plane and data plane operator service accounts.
```bash
oc adm policy add-scc-to-user anyuid \
    system:serviceaccount:istio-system:tsb-operator-control-plane
oc adm policy add-scc-to-user anyuid \
    system:serviceaccount:istio-gateway:tsb-operator-data-plane

```

We can then apply it to the cluster:
```bash
oc apply -f ${FOLDER}/clusteroperators.yaml

```
Verify it is running:
```bash
oc get po -n istio-system -w

```
Should look like this:
```console
$ oc get po -n istio-system
NAME                                         READY   STATUS    RESTARTS   AGE
tsb-operator-control-plane-d5f87f5bb-mf555   1/1     Running   0          15s
```

### Secrets
The control plane needs secrets in order to authenticate with the hosted management plane. The manifest render command for the cluster uses the tctl tool to retrieve tokens to communicate with the management plane automatically, so you only need to provide Elastic credentials, XCP edge certificate secret, and the cluster name (so that the CLI tool can get tokens with the correct scope). Token generation is safe to run multiple times as it does not revoke any previously created tokens.

Then you can run the following command to generate the control plane secrets:
```bash
export ES_HOST=`oc get svc -n es elasticsearch-es-http -o json | jq -r '.status.loadBalancer.ingress[0].hostname'`
export ES_CACERT=`oc get secret elasticsearch-es-http-ca-internal -n es -o json | jq -r '.data."tls.crt"' | base64 -d | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}'`
export ES_PASSWORD=`oc get secret -n es elasticsearch-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 -d`
export XCP_CA_CERT=`oc get secrets -n tsb xcp-central-cert -ojsonpath='{.data.ca\.crt}' | base64 -d`

tctl install manifest control-plane-secrets \
    --cluster "$CLUSTER_NAME" \
    --elastic-password="$ES_PASSWORD" \
    --elastic-username elastic \
    --xcp-central-ca-bundle "$XCP_CA_CERT" \
    --elastic-ca-certificate="$ES_CACERT" > ${FOLDER}/${CLUSTER_NAME}-controlplane-secrets.yaml

```

Apply them to the cluster:
```bash
oc apply -f ${FOLDER}/${CLUSTER_NAME}-controlplane-secrets.yaml

```

You can view the new secrets:
```bash
oc get secrets -n istio-system

```

### Using istio-csr
```bash
oc apply -f example-issuer.yaml

```

> Note: based on this https://raw.githubusercontent.com/cert-manager/istio-csr/main/docs/example-issuer.yaml


> to be replaced with https://cert-manager.io/docs/configuration/venafi/#creating-an-issuer-resource

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

# discovery profile
helm install -n cert-manager cert-manager-istio-csr jetstack/cert-manager-istio-csr --set "app.server.clusterID=${CLUSTER_NAME}"

```

A production configuration would use a static profile
```bash
# static profile
# helm install -n cert-manager cert-manager-istio-csr jetstack/cert-manager-istio-csr \
# 	--set "app.tls.rootCAFile=/var/run/secrets/istio-csr/ca.pem" \
# 	--set "volumeMounts[0].name=root-ca" \
# 	--set "volumeMounts[0].mountPath=/var/run/secrets/istio-csr" \
# 	--set "volumes[0].name=root-ca" \
# 	--set "volumes[0].secret.secretName=istio-root-ca"
```

### Apply the common root CA (created following steps in the PKI folder)

```bash
kubectl create -n istio-system secret generic custom-ca-example-com \
  --from-file=tls.crt=pki/new_certificates/example.com.crt \
  --from-file=tls.key=pki/new_certificates/example.com.key

```

### Creating the Istio control plane for the application cluster

The `app-cluster-cp-template.yaml` file contains the boiler plate configuration for creating a control plane that uses the cert-manager-istio-csr.cert-manager.svc for certificate management.  We will use that and then add in our cluster specifc settings here:

```bash
cat app-cluster-cp-template.yaml > "${FOLDER}/${CLUSTER_NAME}-controlplane-config.yaml"

cat >>"${FOLDER}/${CLUSTER_NAME}-controlplane-config.yaml" <<EOF
  hub: $REGISTRY
  managementPlane:
    host: $TSB_FQDN
    port: 8443
    clusterName: $CLUSTER_NAME
  telemetryStore:
    elastic:
      host: $ES_HOST
      port: 9200
      version: 7
      selfSigned: true
      protocol: https
  meshExpansion: {}
EOF

```

This can then be applied to your Kubernetes cluster:
```bash
oc apply -f ${FOLDER}/${CLUSTER_NAME}-controlplane-config.yaml

```

Again, you will have to allow the service accounts of the different control plane components to your OpenShift Authorization Policies. After the controlplane-config is applied above, run these commands:
```bash
oc adm policy add-scc-to-user anyuid -n istio-system -z istiod-service-account # SA for istiod
oc adm policy add-scc-to-user anyuid -n istio-system -z vmgateway-service-account # SA for vmgateway
oc adm policy add-scc-to-user anyuid -n istio-system -z istio-system-oap # SA for OAP
oc adm policy add-scc-to-user privileged -n istio-system -z xcp-edge # SA for XCP-Edge

```

You can monitor the pods coming up:
```bash
oc get po -n istio-system

```

You should see these pods running - with the onboarding-operator in CrashLoopBackOff:
```console
$ oc get po -n istio-system
NAME                                                     READY   STATUS             RESTARTS   AGE
edge-7d96847559-6bkck                                    1/1     Running            5          61m
istio-operator-7f4787f9b8-qqmrp                          1/1     Running            0          15h
istio-system-custom-metrics-apiserver-6c5d67698c-8wwq7   1/1     Running            0          15h
istiod-69d9d88cc7-26pfz                                  1/1     Running            0          64m
oap-deployment-56d7cbc444-zm6cg                          2/2     Running            0          47m
onboarding-operator-5947659bdc-k2z9w                     0/1     CrashLoopBackOff   12         42m
otel-collector-68fc895cb7-mm67x                          2/2     Running            0          15h
tsb-operator-control-plane-d5f87f5bb-mf555               1/1     Running            0          16h
vmgateway-6dc8498f4-rwglz                                1/1     Running            0          61m
xcp-operator-edge-79c799b458-wj47x                       1/1     Running            0          15h
zipkin-6f4d7bbd64-hlzjk                                  2/2     Running            0          15h
```

In this release, we need to patch the cluster role for the onboarding-operator:
```bash
oc apply -f patches/clusterrole-istio-system-onboarding-operator.yaml

```
Then, delete the onboarding-operator pod - it will be recreated and should start up without error. Of course, you need to replace the pod name:
```bash
oc delete po -n istio-system onboarding-operator-5947659bdc-k2z9w

```


