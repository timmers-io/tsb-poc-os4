# tsb-poc-os4
Tetrate Service Bridge (TSB) on OpenShift 4

## Troubleshooting connectivity
When onboarding a cluster to the TSB management plane (MP), the control plane (CP) needs connectivity to the MP to complete the onboarding process. If the cluster information is not showing in the MP, the following commands can be useful for basic troubleshooting.

## Using the TSB provided containers
We can begin to troubleshoot by testing basic connectivity from the CP to the MP using the tetrate-troubleshoot container included with the TSB images as part of the release.

## Use the kube context for the control plane cluster you want to test from

### Running basic connectivity checks
From the root folder of this project, set these enviroment variables and configure the values to use the tetrate-troubleshoot image.
```bash
export REGISTRY=us-central1-docker.pkg.dev/example/tsb-147
export CONTAINER_IMAGE="${REGISTRY}/tetrate-troubleshoot:1.4.7"
alias ttshoot="kubectl run tmp-shell --rm -i --tty --image $CONTAINER_IMAGE"

```

Now, we can create tmp-shell access by running 'ttshoot' and optionally specifying a namespace to test from:
```bash
ttshoot
```
Or
```bash
ttshoot -n istio-system
```

You should end up at a prompt that looks like this:
```bash
If you don't see a command prompt, try pressing enter.
/ #
```

### Example basic connectivity checks from CP to MP - ports 8443 and 9443
> NOTE: use your FQDN
In the tmp-shell, run the following checks:

Check connectivity to the UI on port 8443
```bash 
curl -ik  https://your.fqdn-here.com:8443
```

You should get a response that includes 'HTTP/1.1 200 OK' and looks something like this:
```console
HTTP/1.1 200 OK
server: envoy
date: Mon, 01 Aug 2022 19:57:56 GMT
content-type: text/html
content-length: 731
last-modified: Mon, 11 Jul 2022 17:50:11 GMT
etag: "62cc62d3-2db"
accept-ranges: bytes
x-envoy-upstream-service-time: 3
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
x-xss-protection: 1; mode=block
content-security-policy: block-all-mixed-content; default-src 'self'; base-uri 'self'; script-src 'self'; font-src 'self'; object-src 'none'; style-src 'unsafe-inline' 'self'; img-src 'self' data:; report-uri /ui/attacks/csp
strict-transport-security: max-age=31536000; includeSubdomains; preload

<!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="shortcut icon" href="/tetrate.ico"/><meta name="viewport" content="width=device-width,initial-scale=1,shrink-to-fit=no"/><meta name="theme-color" content="#000000"/><link rel="manifest" href="/manifest.json"/><title>Tetrate Service Bridge</title><link href="/static/css/4.4b476ad6.chunk.css" rel="stylesheet"><link href="/static/css/main.83fb994b.chunk.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div><script src="/static/js/runtime-main.4e6d8b71.js"></script><script src="/static/js/4.f3c2d4af.chunk.js"></script><script src="/static/js/main.ee50c68a.chunk.js"></script></body></html>
```

> NOTE: you will need to use Control-C to break out of this next command

Check connectivity to the XCP on port 9443
```bash 
openssl s_client -connect your.fqdn-here.com:9443 | grep -i issuer

```

You should get a response that includes 'issuer=CN = ca.xcp.tetrate.io' and looks something like this:
```console
depth=0
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0
verify error:num=21:unable to verify the first certificate
verify return:1
depth=0
verify return:1
issuer=CN = ca.xcp.tetrate.io

```

Type 'exit' to end the tmp-shell session and it will delete the pod.


### Running basic connectivity checks with tctl 

> NOTE: use your FQDN

```bash
tctl config clusters set default --bridge-address your.fqdn-here.com:8443
tctl config clusters set default --tls-insecure

```

Then login interactively or with all params:
```bash
tctl login
tctl login --org tetrate --tenant tetrate --username admin --password Tetrate123
tctl login --org tetrate --tenant tetrate --username admin --password Tetrate123 --debug

```

Now you can test the usual tctl commands:
```bash
tctl get org
tctl get cluster
tctl get tenant

```

Type 'exit' to end the tmp-shell session and it will delete the pod.
