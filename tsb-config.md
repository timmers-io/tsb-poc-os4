# Configuring Tenants, Workspaces, and Groups

## Management Plans

### Creating Tenants

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

