# Install Bookinfo

## Application cluster

### Install the Bookinfo application

From the root folder of this project, set these enviroment variables.
```bash
export FOLDER='./files'
export APP_NS='bookinfo'

```
Set your kubernetes context to the desired cluster.

> ***NOTE***: These sample applications pull from public repositories - change as needed

We will first create a namespace and label it for istio-injection:
```bash
oc create namespace $APP_NS
oc label namespace $APP_NS istio-injection=enabled

```

Apply OpenShift network configuration:
```bash
cat >"${FOLDER}/oc_networkattach.yaml" <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: istio-cni
EOF

```

```bash
oc -n $APP_NS create -f $FOLDER/oc_networkattach.yaml
oc adm policy add-scc-to-group anyuid system:serviceaccounts:$APP_NS

```

Deploy the bookinfo application and a the synthetic load generator
```bash
oc apply -n bookinfo -f apps/bookinfo.yaml
oc apply -n bookinfo -f apps/synthetic-bookinfo.yaml

```

