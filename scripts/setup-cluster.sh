#!/bin/bash

set -e

echo "Creating kind cluster..."

kind create cluster --config kind-config.yaml

echo "Installing metrics server..."

kubectl apply -f \
https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Patching metrics server for kind..."

kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[
    {
      "op":"add",
      "path":"/spec/template/spec/containers/0/args/-",
      "value":"--kubelet-insecure-tls"
    }
  ]'

echo "Installing nginx ingress controller..."

kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress controller..."

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "Cluster setup complete."