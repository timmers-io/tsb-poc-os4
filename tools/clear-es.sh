#!/usr/bin/env bash

#Scale down mgmt stuff
kx 1-5-management
kubectl -n tsb scale deployment oap --replicas=0
kubectl -n tsb scale deployment zipkin --replicas=0
#Scale down workloads
rapture assume tetrate-test/admin
kx 1-5-aws-east
kubectl -n istio-system scale deployment oap-deployment --replicas=0
kubectl -n istio-system scale deployment zipkin --replicas=0
kx 1-5-gke-east
kubectl -n istio-system scale deployment oap-deployment --replicas=0
kubectl -n istio-system scale deployment zipkin --replicas=0
kx 1-5-gke-west
kubectl -n istio-system scale deployment oap-deployment --replicas=0
kubectl -n istio-system scale deployment zipkin --replicas=0
kx gke_abz-perm_us-east4_istio
kubectl -n istio-system scale deployment oap-deployment --replicas=0
kubectl -n istio-system scale deployment zipkin --replicas=0
kx 1-5-management
kubectl -n istio-system scale deployment oap-deployment --replicas=0
kubectl -n istio-system scale deployment zipkin --replicas=0

# Run shell to clear
kx 1-5-management
kubectl run shell -n tsb --rm -i --tty --image nicolaka/netshoot -- /bin/bash 

#Scale up Mgmt
kubectl -n tsb scale deployment oap --replicas=1
kubectl -n tsb scale deployment zipkin --replicas=1
#Sleep
sleep 30
#Scale Up workloads
kx 1-5-management
kubectl -n istio-system scale deployment oap-deployment --replicas=1
kubectl -n istio-system scale deployment zipkin --replicas=1
kx 1-5-aws-east
kubectl -n istio-system scale deployment oap-deployment --replicas=1
kubectl -n istio-system scale deployment zipkin --replicas=1
kx 1-5-gke-east
kubectl -n istio-system scale deployment oap-deployment --replicas=1
kubectl -n istio-system scale deployment zipkin --replicas=1
kx 1-5-gke-west
kubectl -n istio-system scale deployment oap-deployment --replicas=1
kubectl -n istio-system scale deployment zipkin --replicas=1
kx gke_abz-perm_us-east4_istio
kubectl -n istio-system scale deployment oap-deployment --replicas=1
kubectl -n istio-system scale deployment zipkin --replicas=1