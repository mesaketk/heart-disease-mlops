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
