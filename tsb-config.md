# Configuring Tenants, Workspaces, and Groups

## Management Plane

## Creating Tenants

From the root folder of this project, set these enviroment variables.
```bash
export FOLDER='./files'
export TCTL_CONFIG=./files/tctl-config.yaml
export TSB_ORG='tetrate'

```

Before you start:

Verify that you’re logged in to the management plane. If you're not, do with the steps below.

```bash
tctl login --org tetrate --tenant tetrate --username admin --password Tetrate123

tctl get org
tctl get clusters

```

### Create a sample Tenant:

```bash
export TSB_TENANT_NAME='tetrate'
cat >"${FOLDER}/tenant-${TSB_TENANT_NAME}.yaml" <<EOF
apiVersion: api.tsb.tetrate.io/v2
kind: Tenant
metadata:
  organization: ${TSB_ORG}
  name: ${TSB_TENANT_NAME}
spec:
  displayName: ${TSB_TENANT_NAME}
EOF

```

Apply the tenant:
```bash
tctl apply -f ${FOLDER}/tenant-${TSB_TENANT_NAME}.yaml

```

Verify it applied:
```bash
tctl get tenants

```
### Create a sample Workspace:

```bash
export TSB_TENANT_NAME='tetrate'
export TSB_WORKSPACE_NAME='bookinfo-ws'
export CLUSTER_NAME='app-cluster02'

cat >"${FOLDER}/workspace-${TSB_TENANT_NAME}-${TSB_WORKSPACE_NAME}.yaml" <<EOF
apiversion: api.tsb.tetrate.io/v2
kind: Workspace
metadata:
  organization: ${TSB_ORG}
  tenant: ${TSB_TENANT_NAME}
  name: ${TSB_WORKSPACE_NAME}
spec:
  displayName: ${TSB_WORKSPACE_NAME}
  namespaceSelector:
    names:
      - "${CLUSTER_NAME}/bookinfo"
EOF

```

Apply the new workspace:
```bash
tctl apply -f ${FOLDER}/workspace-${TSB_TENANT_NAME}-${TSB_WORKSPACE_NAME}.yaml

```

Verify it was created:
```bash
tctl get workspace --tenant tetrate

```


