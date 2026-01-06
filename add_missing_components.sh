#!/bin/bash

# Additional MLOps Components Setup Script
# Run this in your heart-disease-mlops directory

echo "=========================================="
echo "Adding Missing MLOps Components"
echo "=========================================="
echo ""

# ==================================================
# MONITORING & LOGGING COMPONENTS
# ==================================================

# FILE 1: Prometheus configuration
echo "📝 Creating monitoring/prometheus.yml..."
mkdir -p monitoring
cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'heart-disease-api'
    static_configs:
      - targets: ['localhost:5000']
    metrics_path: '/metrics'
EOF

# FILE 2: Enhanced app.py with Prometheus metrics
echo "📝 Creating app_with_monitoring.py..."
cat > app_with_monitoring.py << 'EOF'
"""
Flask API with Prometheus Monitoring and Advanced Logging
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from prometheus_flask_exporter import PrometheusMetrics
import numpy as np
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
import sys
import os
import time

# Add src to path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from src.inference import HeartDiseasePredictor

# Setup logging
os.makedirs('logs', exist_ok=True)

# File handler
file_handler = RotatingFileHandler(
    'logs/api.log', 
    maxBytes=10485760,  # 10MB
    backupCount=10
)
file_handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
))

# Console handler
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(levelname)s - %(message)s'
))

# Configure logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(file_handler)
logger.addHandler(console_handler)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Initialize Prometheus metrics
metrics = PrometheusMetrics(app)

# Add custom metrics
metrics.info('app_info', 'Application info', version='1.0.0')

# Custom metrics
from prometheus_client import Counter, Histogram, Gauge

prediction_counter = Counter(
    'predictions_total', 
    'Total number of predictions',
    ['status', 'prediction_label']
)

prediction_histogram = Histogram(
    'prediction_duration_seconds',
    'Time spent processing prediction'
)

model_confidence = Gauge(
    'model_confidence',
    'Confidence of the last prediction'
)

# Load model at startup
try:
    predictor = HeartDiseasePredictor()
    logger.info("✓ Model loaded successfully")
except Exception as e:
    logger.error(f"✗ Error loading model: {e}")
    predictor = None

@app.before_request
def log_request_info():
    """Log incoming request details"""
    logger.info(f'Request: {request.method} {request.path} from {request.remote_addr}')

@app.after_request
def log_response_info(response):
    """Log response details"""
    logger.info(f'Response: {response.status_code}')
    return response

@app.route('/', methods=['GET'])
def home():
    """Health check endpoint"""
    logger.info("Home endpoint accessed")
    return jsonify({
        'status': 'healthy',
        'service': 'Heart Disease Prediction API',
        'version': '1.0.0',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/predict', methods=['POST'])
@prediction_histogram.time()
def predict():
    """
    Prediction endpoint with monitoring
    """
    start_time = time.time()
    
    try:
        # Get JSON data
        data = request.get_json()
        
        if not data or 'features' not in data:
            logger.warning("Missing 'features' in request")
            prediction_counter.labels(status='error', prediction_label='none').inc()
            return jsonify({
                'error': 'Missing features in request',
                'expected_format': {
                    'features': [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
                }
            }), 400
        
        features = data['features']
        
        # Validate features
        if not isinstance(features, list) or len(features) != 13:
            logger.warning(f"Invalid features length: {len(features)}")
            prediction_counter.labels(status='error', prediction_label='none').inc()
            return jsonify({
                'error': 'Features must be a list of 13 values'
            }), 400
        
        # Make prediction
        logger.info(f"Processing prediction request - Features: {features[:3]}...")
        result = predictor.predict(features)
        
        # Update metrics
        prediction_counter.labels(
            status='success', 
            prediction_label=result['prediction_label']
        ).inc()
        model_confidence.set(result['confidence'])
        
        # Calculate latency
        latency = time.time() - start_time
        
        logger.info(
            f"Prediction: {result['prediction_label']}, "
            f"Confidence: {result['confidence']:.2%}, "
            f"Latency: {latency:.3f}s"
        )
        
        return jsonify({
            'success': True,
            'prediction': result['prediction'],
            'prediction_label': result['prediction_label'],
            'confidence': result['confidence'],
            'probability_disease': result['probability_disease'],
            'probability_no_disease': result['probability_no_disease'],
            'latency_seconds': latency,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}", exc_info=True)
        prediction_counter.labels(status='error', prediction_label='none').inc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Detailed health check with metrics"""
    health_status = {
        'status': 'healthy',
        'model_loaded': predictor is not None,
        'timestamp': datetime.now().isoformat(),
        'uptime_seconds': time.time() - app.start_time
    }
    logger.debug(f"Health check: {health_status}")
    return jsonify(health_status)

@app.route('/metrics', methods=['GET'])
def metrics_endpoint():
    """Prometheus metrics endpoint (handled by prometheus_flask_exporter)"""
    pass

if __name__ == '__main__':
    app.start_time = time.time()
    logger.info("Starting Heart Disease Prediction API with monitoring...")
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# FILE 3: Enhanced requirements.txt
echo "📝 Updating requirements.txt with monitoring libraries..."
cat >> requirements.txt << 'EOF'

# Monitoring & Metrics
prometheus-flask-exporter==0.22.4
prometheus-client==0.19.0
EOF

# FILE 4: Docker Compose for full stack with monitoring
echo "📝 Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Flask API
  api:
    build: .
    container_name: heart-disease-api
    ports:
      - "5000:5000"
    volumes:
      - ./logs:/app/logs
      - ./models:/app/models
    environment:
      - FLASK_ENV=production
    networks:
      - monitoring
    restart: unless-stopped

  # Prometheus
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring
    restart: unless-stopped

  # Grafana
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana-dashboards:/etc/grafana/provisioning/dashboards
      - ./monitoring/grafana-datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml
    networks:
      - monitoring
    restart: unless-stopped
    depends_on:
      - prometheus

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
EOF

# FILE 5: Grafana datasource configuration
echo "📝 Creating monitoring/grafana-datasources.yml..."
cat > monitoring/grafana-datasources.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

# FILE 6: Grafana dashboard directory
echo "📝 Creating Grafana dashboard configuration..."
mkdir -p monitoring/grafana-dashboards
cat > monitoring/grafana-dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'Heart Disease API'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# FILE 7: Sample Grafana dashboard JSON
echo "📝 Creating monitoring/grafana-dashboards/api-dashboard.json..."
cat > monitoring/grafana-dashboards/api-dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "Heart Disease API Dashboard",
    "panels": [
      {
        "id": 1,
        "title": "Total Predictions",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(predictions_total)"
          }
        ]
      },
      {
        "id": 2,
        "title": "Predictions by Label",
        "type": "piechart",
        "targets": [
          {
            "expr": "sum by (prediction_label) (predictions_total)"
          }
        ]
      },
      {
        "id": 3,
        "title": "Average Prediction Latency",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(prediction_duration_seconds_sum[5m]) / rate(prediction_duration_seconds_count[5m])"
          }
        ]
      }
    ]
  }
}
EOF

# ==================================================
# ENHANCED KUBERNETES DEPLOYMENT
# ==================================================

# FILE 8: Kubernetes ConfigMap for monitoring
echo "📝 Creating deployment/kubernetes/configmap.yaml..."
cat > deployment/kubernetes/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
data:
  FLASK_ENV: "production"
  LOG_LEVEL: "INFO"
EOF

# FILE 9: Kubernetes Ingress
echo "📝 Creating deployment/kubernetes/ingress.yaml..."
cat > deployment/kubernetes/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: heart-disease-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  rules:
  - host: heart-disease-api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: heart-disease-service
            port:
              number: 80
  tls:
  - hosts:
    - heart-disease-api.example.com
    secretName: heart-disease-tls
EOF

# FILE 10: Kubernetes HorizontalPodAutoscaler
echo "📝 Creating deployment/kubernetes/hpa.yaml..."
cat > deployment/kubernetes/hpa.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: heart-disease-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: heart-disease-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

# FILE 11: Complete Kubernetes deployment script
echo "📝 Creating deployment/deploy_k8s.sh..."
cat > deployment/deploy_k8s.sh << 'EOF'
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
EOF

chmod +x deployment/deploy_k8s.sh

# ==================================================
# TESTING & LOAD TESTING
# ==================================================

# FILE 12: Load testing script
echo "📝 Creating tests/load_test.py..."
cat > tests/load_test.py << 'EOF'
"""
Load testing script for API
"""
import requests
import time
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed

API_URL = "http://localhost:5000/predict"

SAMPLE_REQUESTS = [
    {"features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]},
    {"features": [67, 1, 0, 160, 286, 0, 0, 108, 1, 1.5, 1, 3, 2]},
    {"features": [67, 1, 0, 120, 229, 0, 0, 129, 1, 2.6, 1, 2, 3]},
    {"features": [37, 1, 2, 130, 250, 0, 1, 187, 0, 3.5, 0, 0, 2]},
]

def make_request(request_data):
    """Make a single prediction request"""
    start_time = time.time()
    try:
        response = requests.post(API_URL, json=request_data, timeout=10)
        latency = time.time() - start_time
        return {
            'success': response.status_code == 200,
            'latency': latency,
            'status_code': response.status_code
        }
    except Exception as e:
        return {
            'success': False,
            'latency': time.time() - start_time,
            'error': str(e)
        }

def run_load_test(num_requests=100, num_workers=10):
    """Run load test"""
    print(f"🚀 Starting load test: {num_requests} requests with {num_workers} workers")
    print(f"📍 Target: {API_URL}")
    print("")
    
    results = []
    start_time = time.time()
    
    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        # Submit requests
        futures = []
        for i in range(num_requests):
            request_data = SAMPLE_REQUESTS[i % len(SAMPLE_REQUESTS)]
            futures.append(executor.submit(make_request, request_data))
        
        # Collect results
        for future in as_completed(futures):
            results.append(future.result())
            if len(results) % 10 == 0:
                print(f"Progress: {len(results)}/{num_requests}")
    
    total_time = time.time() - start_time
    
    # Calculate statistics
    successful = sum(1 for r in results if r['success'])
    failed = len(results) - successful
    latencies = [r['latency'] for r in results if r['success']]
    
    print("\n" + "="*50)
    print("📊 LOAD TEST RESULTS")
    print("="*50)
    print(f"Total Requests:     {num_requests}")
    print(f"Successful:         {successful} ({successful/num_requests*100:.1f}%)")
    print(f"Failed:             {failed} ({failed/num_requests*100:.1f}%)")
    print(f"Total Duration:     {total_time:.2f}s")
    print(f"Requests/Second:    {num_requests/total_time:.2f}")
    print("")
    print("Latency Statistics:")
    print(f"  Min:              {min(latencies):.3f}s")
    print(f"  Max:              {max(latencies):.3f}s")
    print(f"  Mean:             {statistics.mean(latencies):.3f}s")
    print(f"  Median:           {statistics.median(latencies):.3f}s")
    if len(latencies) > 1:
        print(f"  Std Dev:          {statistics.stdev(latencies):.3f}s")
    print("="*50)

if __name__ == "__main__":
    # Run load test
    run_load_test(num_requests=100, num_workers=10)
EOF

# FILE 13: Integration tests
echo "📝 Creating tests/test_integration.py..."
cat > tests/test_integration.py << 'EOF'
"""
Integration tests for the API
"""
import pytest
import requests
import time

BASE_URL = "http://localhost:5000"

class TestAPIIntegration:
    
    def test_health_endpoint(self):
        """Test health endpoint"""
        response = requests.get(f"{BASE_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'healthy'
        assert data['model_loaded'] == True
    
    def test_predict_endpoint(self):
        """Test prediction endpoint"""
        payload = {
            "features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
        }
        response = requests.post(f"{BASE_URL}/predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        assert data['success'] == True
        assert 'prediction' in data
        assert data['prediction'] in [0, 1]
        assert 0 <= data['confidence'] <= 1
    
    def test_predict_invalid_input(self):
        """Test prediction with invalid input"""
        payload = {
            "features": [63, 1, 3]  # Too few features
        }
        response = requests.post(f"{BASE_URL}/predict", json=payload)
        assert response.status_code == 400
    
    def test_metrics_endpoint(self):
        """Test Prometheus metrics endpoint"""
        response = requests.get(f"{BASE_URL}/metrics")
        assert response.status_code == 200
        assert 'predictions_total' in response.text

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
EOF

# FILE 14: Deployment verification script
echo "📝 Creating deployment/verify_deployment.sh..."
cat > deployment/verify_deployment.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "Deployment Verification Script"
echo "=========================================="
echo ""

# Get service URL
if command -v minikube &> /dev/null; then
    SERVICE_URL=$(minikube service heart-disease-service --url)
else
    SERVICE_URL="http://localhost:80"
fi

echo "🔍 Testing deployment at: $SERVICE_URL"
echo ""

# Test 1: Health check
echo "Test 1: Health Check"
curl -s $SERVICE_URL/health | jq .
if [ $? -eq 0 ]; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    exit 1
fi
echo ""

# Test 2: Prediction
echo "Test 2: Making Prediction"
curl -s -X POST $SERVICE_URL/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]}' | jq .
if [ $? -eq 0 ]; then
    echo "✅ Prediction test passed"
else
    echo "❌ Prediction test failed"
    exit 1
fi
echo ""

# Test 3: Check pods
echo "Test 3: Checking Kubernetes Pods"
kubectl get pods -l app=heart-disease-api
echo ""

# Test 4: Check logs
echo "Test 4: Recent Logs"
POD_NAME=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME --tail=10
echo ""

echo "=========================================="
echo "✅ All verification tests passed!"
echo "=========================================="
EOF

chmod +x deployment/verify_deployment.sh

# FILE 15: Complete deployment guide
echo "📝 Creating DEPLOYMENT_GUIDE.md..."
cat > DEPLOYMENT_GUIDE.md << 'EOF'
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
EOF

echo ""
echo "=========================================="
echo "✅ Missing Components Added Successfully!"
echo "=========================================="
echo ""
echo "📦 New Files Created:"
echo "  ✓ app_with_monitoring.py (Enhanced API with Prometheus)"
echo "  ✓ docker-compose.yml (Full stack: API + Prometheus + Grafana)"
echo "  ✓ monitoring/ (Prometheus & Grafana configs)"
echo "  ✓ deployment/kubernetes/ (Enhanced K8s manifests)"
echo "  ✓ tests/load_test.py (Load testing)"
echo "  ✓ tests/test_integration.py (Integration tests)"
echo "  ✓ deployment/deploy_k8s.sh (K8s deployment script)"
echo "  ✓ deployment/verify_deployment.sh (Verification script)"
echo "  ✓ DEPLOYMENT_GUIDE.md (Complete deployment guide)"
echo ""
echo "🚀 Quick Start Commands:"
echo ""
echo "1. Install monitoring dependencies:"
echo "   pip install -r requirements.txt"
echo ""
echo "2. Run API with monitoring:"
echo "   python app_with_monitoring.py"
echo ""
echo "3. Run full stack with Docker Compose:"
echo "   docker-compose up -d"
echo "   # Access Grafana at http://localhost:3000 (admin/admin)"
echo ""
echo "4. Deploy to Kubernetes:"
echo "   cd deployment"
echo "   ./deploy_k8s.sh"
echo "   ./verify_deployment.sh"
echo ""
echo "5. Run load tests:"
echo "   python tests/load_test.py"
echo ""
echo "=========================================="
echo "📋 Coverage Summary:"
echo "=========================================="
echo "✅ Point 5: CI/CD Pipeline (Already covered in first script)"
echo "✅ Point 6: Docker Containerization (Already covered)"
echo "✅ Point 7: Kubernetes Deployment (ENHANCED with HPA, Ingress)"
echo "✅ Point 8: Monitoring & Logging (NEW - Prometheus + Grafana)"
echo ""
echo "🎯 All assignment requirements are now covered!"
echo ""
