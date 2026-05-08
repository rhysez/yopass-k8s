#!/bin/bash

set -e

echo "Adding helm repositories..."

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add rlex https://rlex.github.io/helm-charts

helm repo update

echo "Installing Redis..."

helm install redis bitnami/redis \
  -f helm-values/redis-values.yaml

echo "Installing Yopass..."

helm install yopass rlex/yopass \
  -f helm-values/yopass-values.yaml

echo "Applying ingress..."

kubectl apply -f k8s/ingress.yaml

echo "Applying autoscaler..."

kubectl apply -f k8s/hpa.yaml

echo "Deployment complete."