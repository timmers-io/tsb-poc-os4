export FOLDER='.'
export REGISTRY='localhost:32000'

cat >"${FOLDER}/tctl-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tctl
  labels:
    app: tctl
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tctl
  template:
    metadata:
      labels:
        app: tctl
    spec:
      containers:
      - name: tctl
        image: $REGISTRY/tctl:1.4.0
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo hello; sleep 10;done"]
EOF

k apply -f ${FOLDER}/tctl-deployment.yaml

#k exec -it tctl-xxx -n tsb -- sh
