# Install Istio 

## Application cluster - EKS

### Install Istio on the application cluster
This page explains how to onboard a Kubernetes cluster to an existing Tetrate Service Bridge management plane.

From the root folder of this project, set these enviroment variables.
```bash
export FOLDER='./files'
export TSB_FQDN="tsb.example.tetrate.com"
export REGISTRY=us-central1-docker.pkg.dev/example/tsb-147
export CLUSTER_NAME="app-cluster03"

```

Before you start:

Verify that you’re logged in to the management plane. If you're not, do with the steps below.

```bash
tctl login --org tetrate --tenant tetrate --username admin --password Tetrate123

tctl get org

```
Configuring the Management Plane

To create the correct credentials for the cluster to communicate with the management plane, we need to create a cluster object using the management plane API.

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

We can then apply it to the cluster:
```bash
kubectl apply -f ${FOLDER}/clusteroperators.yaml

```
Verify it is running:
```bash
kubectl get po -n istio-system

```
Should look like this:
```console
$ kubectl get po -n istio-system
NAME                                         READY   STATUS    RESTARTS   AGE
tsb-operator-control-plane-d5f87f5bb-mf555   1/1     Running   0          15s
```

### Secrets
The control plane needs secrets in order to authenticate with the hosted management plane. The manifest render command for the cluster uses the tctl tool to retrieve tokens to communicate with the management plane automatically, so you only need to provide Elastic credentials, XCP edge certificate secret, and the cluster name (so that the CLI tool can get tokens with the correct scope). Token generation is safe to run multiple times as it does not revoke any previously created tokens.

> ***NOTE***: Change your k8s context to point to the mp cluster so we can pull the credentials to pass into the tctl command

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
> ***NOTE***: Change your k8s context to point to the application cluster

Apply them to the cluster:
```bash
kubectl apply -f ${FOLDER}/${CLUSTER_NAME}-controlplane-secrets.yaml

```

You can view the new secrets:
```bash
kubectl get secrets -n istio-system

```

### Install cert-manager

Install cert-manager v1.7.2
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.2/cert-manager.yaml

```

Verify the installation
```bash
kubectl get all -n cert-manager

```

### Using istio-csr
```bash
kubectl apply -f https://raw.githubusercontent.com/cert-manager/istio-csr/main/docs/example-issuer.yaml

```

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

### Creating the Istio control plane for the application cluster

The `app-cluster-cp-template.yaml` file contains the boiler plate configuration for creating a control plane that uses the cert-manager-istio-csr.cert-manager.svc for certificate management.  We will use that and then add in our cluster specifc settings here:

```bash
cat app-cluster-cp-eks-template.yaml > "${FOLDER}/${CLUSTER_NAME}-controlplane-config.yaml"

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
kubectl apply -f ${FOLDER}/${CLUSTER_NAME}-controlplane-config.yaml

```

You can monitor the pods coming up:
```bash
kubectl get po -n istio-system

```

You should see these pods running - with the onboarding-operator in CrashLoopBackOff:
```console
$ kubectl get po -n istio-system
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
kubectl apply -f patches/clusterrole-istio-system-onboarding-operator.yaml

```
Then, delete the onboarding-operator pod - it will be recreated and should start up without error. Of course, you need to replace the pod name:
```bash
kubectl delete po -n istio-system onboarding-operator-5947659bdc-k2z9w

```

If you see the oap-deployment in CrashLoopBackOff, delete the pod and it will be recreated
```console
oap-deployment-84f494c8d5-9jr8r                          1/2     CrashLoopBackOff   4          3m24s
```
