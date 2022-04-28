# Install and verify Elasticsearch

## Management plane cluster

### Install Elasticsearch

From the root folder of this project, set these enviroment variables
```bash
export FOLDER='./files'
export TSB_FQDN="tiaa-alpha.cx.tetrate.info"

```

Installing Elasticsearch using the operator
```bash
oc create -f https://download.elastic.co/downloads/eck/2.1.0/crds.yaml
oc apply -f https://download.elastic.co/downloads/eck/2.1.0/operator.yaml

```

Configure and create an Elasticsearch instance in the es namespace
```bash
oc create ns es 

```

```bash
cat >"${FOLDER}/es-eck-7.15.2.yaml" <<EOF
# This sample sets up an Elasticsearch cluster with an OpenShift route
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
spec:
  version: 7.15.2
  http:
    service:
      spec:
        type: LoadBalancer
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
EOF

```

```bash
oc apply -f "${FOLDER}/es-eck-7.15.2.yaml" -n es

```

### Verify the installation

```bash
oc get all -n es

```

