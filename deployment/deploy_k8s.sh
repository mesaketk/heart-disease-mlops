#!/bin/bash

echo "=========================================="
echo "Kubernetes Deployment Script"
echo "=========================================="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if minikube is running (for local deployment)
if command -v minikube &> /dev/null; then
    if ! minikube status &> /dev/null; then
        echo "Starting Minikube..."
        minikube start
    fi
    
    # Load Docker image into Minikube
    echo "Loading Docker image into Minikube..."
    minikube image load heart-disease-api:latest
fi

echo "📦 Applying Kubernetes manifests..."

# Apply ConfigMap
kubectl apply -f kubernetes/configmap.yaml

# Apply Deployment
kubectl apply -f kubernetes/deployment.yaml

# Apply Service
kubectl apply -f kubernetes/service.yaml

# Apply HPA (optional)
kubectl apply -f kubernetes/hpa.yaml

# Apply Ingress (optional, requires ingress controller)
# kubectl apply -f kubernetes/ingress.yaml

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Checking deployment status..."
kubectl get deployments
echo ""
kubectl get pods
echo ""
kubectl get services
echo ""

# Get service URL (for Minikube)
if command -v minikube &> /dev/null; then
    echo "🌐 Getting service URL..."
    minikube service heart-disease-service --url
fi

echo ""
echo "📝 Useful commands:"
echo "  kubectl get pods                          # Check pod status"
echo "  kubectl logs -f <pod-name>                # View logs"
echo "  kubectl describe pod <pod-name>           # Pod details"
echo "  kubectl port-forward svc/heart-disease-service 8080:80  # Port forward"
echo ""
