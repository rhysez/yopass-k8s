# yopass-k8s
A horizontally scalable yopass deployment to K8S infrastraucture.

## Getting started
You will find a set of shell scripts in `scripts/`. They deal with creating the cluster with `kind`, deploying service definitions to the cluster and load testing.

- You can create the cluster from the kind config found at the root of the project with `setup-cluster.sh`
- You can then deploy service definitions to the cluster with `deploy.sh`, this ensures that the cluster knows which containers it needs to run and where to pull the corresponding images from. 
- You can test that the application is running at http://yopass.radioco.local by running `test-domain-up.sh` which will ping the URL. If there are bytes being transferred, then the app is working.
- You can run a stress/load test on the application by running `load-test.sh`, this script uses `hey` to simulate heavy traffic on the domain.
- You can delete the cluster by running `cleanup.sh`

It's worth noting that running these scripts requires system permissions, so run `chmod +x scripts/*.sh` to ensure that all of these scripts are executable.

## Architecture breakdown
There are a few services being used in this project that I wanted to provide explicit definitions for, mainly for my own knowledge retention.

- `kind` is being used to create and destroy the local K8S cluster
- `kubectl` is being used to interact with the cluster, deploy new container definitions and for general observability.
- `helm` is being used as a K8S package manager, allowing us to pull helm charts from a remote repository. This has allowed me to reduce the amount of YAML I'm writing for container definitions. Values files still exist for these in the project so that we can override certain fields. Any fields that do not need to change are not included.

Here is a very simple communication workflow, shown below

```
Browser (yopass.radioco.local)
↓  
Ingress (HTTP entrypoint)  
↓  
Yopass Pods (2–5 replicas)  
↓  
Redis
```

The cluster control plane node is exposed on port 80, and the ingress acts as the HTTP entrypoint. The K8S ingress is what allows us to actually speak with the application from outside of it (for example, from a browser). The ingress host name has been assigned to 'yopass.radioco.local', you can see the implementation of this in `k8s/ingress.yaml`.

At minimum we run 2 Yopass replicas at all times. In the event that traffic becomes particularly high, we can scale up to a maximum of 5 replicas. This is handled automatically via autoscaling using `hpa`, of which the config can be found in `k8s/hpa.yaml`.

The cluster contains **worker nodes**. These are essentially individual machines that run **pods** (services/processes/containers).

The individual application processes (e.g. yopass, redis) run in **pods**. In this project, the pods are auto-scaled up to a max of 5 replicas when needed.

## Helm workflow
If I wanted to, I could have opted out of using helm and just created the full charts myself, however I thought it would be better to use helm.

Once the cluster is created by kind using `kind create cluster`, service definitions need to be added to the cluster, otherwise the cluster doesn't have anything to run. The workflow goes as follows:

1. Add the repo that contains the service you need. For example, in this project we are using the redis service, which is found within the 'bitnami' repo. So we run `helm repo add bitnami https://charts.bitnami.com/bitnami` to get access to the services under the repo.
2. Install and create the full chart for the service using `helm install redis bitnami/redis -f helm-values/redis-values.yaml`. This updates the chart with any overridden fields found in `redis-values.yaml`. When executing this command, we are naming the service 'redis' and using the chart template found in 'bitnami/redis'. 

## Bare chart workflow (no helm)
The charts found in `k8s/` do not rely on helm templates, instead they contain the full definition for the service. In order to add these services to our cluster, we just need to run `kubectl apply -f k8s/<service_name.yaml>`. This will update the cluster with that service. 

For example, running `kubectl apply -f k8s/ingress.yaml` will publish the ingress service to the cluster, allowing us to access the application externally via https://yopass.radioco.local.



