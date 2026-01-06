# Complete Deployment Guide

## Prerequisites

### Required Tools
```bash
# Docker
docker --version

# Kubernetes (choose one)
kubectl version
minikube version
# OR
gcloud --version  # For GKE
aws --version     # For EKS
az --version      # For AKS

# Monitoring
docker-compose --version
```

## Local Development Setup

### 1. Run API Locally
```bash
python app_with_monitoring.py
```

### 2. Run with Docker
```bash
# Build image
docker build -t heart-disease-api .

# Run container
docker run -p 5000:5000 heart-disease-api

# Test
curl http://localhost:5000/health
```

### 3. Run Full Stack with Monitoring
```bash
# Start all services (API + Prometheus + Grafana)
docker-compose up -d

# Access services:
# API:        http://localhost:5000
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3000 (admin/admin)
```

## Kubernetes Deployment

### Option 1: Local (Minikube)

```bash
# Start Minikube
minikube start

# Build and load image
docker build -t heart-disease-api:latest .
minikube image load heart-disease-api:latest

# Deploy
cd deployment
./deploy_k8s.sh

# Get service URL
minikube service heart-disease-service --url

# Verify deployment
./verify_deployment.sh
```

### Option 2: Google Kubernetes Engine (GKE)

```bash
# Create cluster
gcloud container clusters create heart-disease-cluster \
  --num-nodes=3 \
  --zone=us-central1-a

# Configure kubectl
gcloud container clusters get-credentials heart-disease-cluster \
  --zone=us-central1-a

# Build and push image
docker build -t gcr.io/YOUR_PROJECT_ID/heart-disease-api:latest .
docker push gcr.io/YOUR_PROJECT_ID/heart-disease-api:latest

# Update deployment.yaml with your image
# Then deploy
kubectl apply -f deployment/kubernetes/

# Get external IP
kubectl get service heart-disease-service
```

### Option 3: AWS EKS

```bash
# Create cluster
eksctl create cluster \
  --name heart-disease-cluster \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3

# Build and push to ECR
aws ecr create-repository --repository-name heart-disease-api
docker build -t YOUR_ACCOUNT.dkr.ecr.us-west-2.amazonaws.com/heart-disease-api:latest .
docker push YOUR_ACCOUNT.dkr.ecr.us-west-2.amazonaws.com/heart-disease-api:latest

# Deploy
kubectl apply -f deployment/kubernetes/

# Get load balancer URL
kubectl get service heart-disease-service
```

## Monitoring Setup

### Prometheus Metrics
```bash
# Access Prometheus UI
# If using docker-compose: http://localhost:9090
# If using k8s: kubectl port-forward svc/prometheus 9090:9090

# Available metrics:
# - predictions_total
# - prediction_duration_seconds
# - model_confidence
# - http_request_duration_seconds
```

### Grafana Dashboards
```bash
# Access Grafana
# If using docker-compose: http://localhost:3000
# Login: admin/admin

# Add Prometheus datasource (already configured in docker-compose)
# Import dashboard from monitoring/grafana-dashboards/api-dashboard.json
```

## Testing Deployment

### Load Testing
```bash
# Run load test
python tests/load_test.py

# Run integration tests
pytest tests/test_integration.py -v
```

### Manual Testing
```bash
# Health check
curl http://YOUR_ENDPOINT/health

# Make prediction
curl -X POST http://YOUR_ENDPOINT/predict \
  -H "Content-Type: application/json" \
  -d '{
    "features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
  }'

# Check metrics
curl http://YOUR_ENDPOINT/metrics
```

## Capturing Screenshots

### Required Screenshots for Assignment

1. **MLflow UI**
```bash
mlflow ui
# Screenshot: http://localhost:5000
# Show: Experiments, runs, metrics comparison
```

2. **Docker Container Running**
```bash
docker ps
docker logs <container_id>
# Screenshot: Container status and logs
```

3. **Kubernetes Deployment**
```bash
kubectl get all
kubectl describe deployment heart-disease-api
# Screenshot: Deployment status, pods, services
```

4. **API Response**
```bash
# Screenshot: curl command and JSON response
```

5. **Prometheus Metrics**
```bash
# Screenshot: Prometheus UI showing custom metrics
```

6. **Grafana Dashboard**
```bash
# Screenshot: Dashboard with graphs
```

7. **Load Test Results**
```bash
python tests/load_test.py
# Screenshot: Terminal output with statistics
```

## Troubleshooting

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Image pull errors:**
```bash
# For Minikube
minikube image load heart-disease-api:latest

# For cloud providers
# Ensure proper image registry authentication
```

**Service not accessible:**
```bash
# Check service
kubectl get svc
kubectl describe svc heart-disease-service

# Port forward for testing
kubectl port-forward svc/heart-disease-service 8080:80
```

## Cleanup

### Local Docker
```bash
docker-compose down
docker rmi heart-disease-api
```

### Kubernetes (Minikube)
```bash
kubectl delete -f deployment/kubernetes/
minikube stop
minikube delete
```

### Cloud (GKE/EKS/AKS)
```bash
kubectl delete -f deployment/kubernetes/
# Then delete cluster via cloud console or CLI
```

## Cost Optimization

- Use spot/preemptible instances for non-production
- Set resource limits in deployment.yaml
- Use HPA for auto-scaling
- Clean up resources when not in use

## Security Best Practices

- Use secrets for sensitive data
- Enable RBAC
- Use network policies
- Regular security scans
- HTTPS with proper certificates
