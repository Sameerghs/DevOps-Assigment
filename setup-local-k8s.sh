#!/bin/bash

# Set the namespace for monitoring and argocd
ARGOCD_NAMESPACE="argocd"
MONITORING_NAMESPACE="monitoring"

# Start Minikube with Docker driver
echo "Starting Minikube with Docker driver..."
minikube start --driver=docker --memory=4g --cpus=2

# Set kubectl context to Minikube
echo "Setting kubectl context to Minikube..."
kubectl config use-context minikube

# Install Helm if it's not installed
if ! command -v helm &> /dev/null
then
    echo "Helm not found, installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "Helm already installed"
fi

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create the ArgoCD namespace and install ArgoCD
echo "Creating ArgoCD namespace and installing ArgoCD..."
kubectl create namespace $ARGOCD_NAMESPACE || echo "Namespace $ARGOCD_NAMESPACE already exists"
helm install argocd argo/argo-cd -n $ARGOCD_NAMESPACE -f values-argocd.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment -n $ARGOCD_NAMESPACE --all

# Create the Monitoring namespace and install Prometheus
echo "Creating Monitoring namespace and installing Prometheus..."
kubectl create namespace $MONITORING_NAMESPACE || echo "Namespace $MONITORING_NAMESPACE already exists"
helm install prometheus prometheus-community/prometheus -n $MONITORING_NAMESPACE -f values-prometheus.yaml

# Wait for Prometheus to be ready
echo "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment -n $MONITORING_NAMESPACE --all

# Install Grafana
echo "Installing Grafana..."
helm install grafana grafana/grafana -n $MONITORING_NAMESPACE -f values-grafana.yaml

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment -n $MONITORING_NAMESPACE --all

# Provide information for accessing services
echo "All services are installed and running!"
echo "ArgoCD UI: http://localhost:8080"
echo "Prometheus UI: http://localhost:9090"
echo "Grafana UI: http://localhost:3000"

echo "You can port-forward the services if needed."

