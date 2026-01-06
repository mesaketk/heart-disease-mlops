#!/bin/bash

echo "=========================================="
echo "Testing API Monitoring Endpoints"
echo "=========================================="
echo ""

API_URL="http://localhost:5000"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo "Test 1: Health Check"
echo "--------------------"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}/health)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$HEALTH_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    echo "$RESPONSE_BODY" | jq . 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo -e "${RED}✗ Health check failed (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 2: Make a prediction (to generate metrics)
echo "Test 2: Make Prediction (generates metrics)"
echo "--------------------------------------------"
PREDICT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST ${API_URL}/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]}')

HTTP_CODE=$(echo "$PREDICT_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$PREDICT_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Prediction successful${NC}"
    echo "$RESPONSE_BODY" | jq . 2>/dev/null || echo "$RESPONSE_BODY"
else
    echo -e "${RED}✗ Prediction failed (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 3: Check Metrics Endpoint
echo "Test 3: Metrics Endpoint"
echo "------------------------"
METRICS_RESPONSE=$(curl -s -w "\n%{http_code}" ${API_URL}/metrics)
HTTP_CODE=$(echo "$METRICS_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$METRICS_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Metrics endpoint working${NC}"
    echo ""
    echo "Sample metrics:"
    echo "$RESPONSE_BODY" | grep -E "predictions_total|prediction_duration|model_confidence|http_requests" | head -20
    echo ""
    echo "Full metrics available at: ${API_URL}/metrics"
else
    echo -e "${RED}✗ Metrics endpoint failed (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test 4: Make more predictions to see metrics increase
echo "Test 4: Generate More Metrics (10 predictions)"
echo "-----------------------------------------------"
echo "Making 10 predictions..."

for i in {1..10}; do
    curl -s -X POST ${API_URL}/predict \
      -H "Content-Type: application/json" \
      -d '{"features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]}' \
      > /dev/null
    echo -n "."
done
echo ""
echo -e "${GREEN}✓ Made 10 predictions${NC}"
echo ""

# Test 5: Check updated metrics
echo "Test 5: Verify Metrics Increased"
echo "---------------------------------"
METRICS=$(curl -s ${API_URL}/metrics)

# Extract specific metrics
TOTAL_PREDICTIONS=$(echo "$METRICS" | grep 'predictions_total{' | grep -v '#' | awk '{sum+=$2} END {print sum}')
TOTAL_REQUESTS=$(echo "$METRICS" | grep 'http_requests_total{' | grep -v '#' | awk '{sum+=$2} END {print sum}')

echo "Total Predictions: $TOTAL_PREDICTIONS"
echo "Total HTTP Requests: $TOTAL_REQUESTS"
echo ""

if [ ! -z "$TOTAL_PREDICTIONS" ] && [ "$TOTAL_PREDICTIONS" -gt 0 ]; then
    echo -e "${GREEN}✓ Metrics are being collected!${NC}"
else
    echo -e "${YELLOW}⚠ Metrics might not be working properly${NC}"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "✓ API is running at: ${API_URL}"
echo "✓ Metrics available at: ${API_URL}/metrics"
echo "✓ For Prometheus: Add target 'localhost:5000' to prometheus.yml"
echo ""
echo "To view in Prometheus:"
echo "  1. Start Prometheus: docker-compose up prometheus -d"
echo "  2. Open: http://localhost:9090"
echo "  3. Query: predictions_total"
echo ""
echo "To view in Grafana:"
echo "  1. Start Grafana: docker-compose up grafana -d"
echo "  2. Open: http://localhost:3000 (admin/admin)"
echo "  3. Add Prometheus datasource"
echo "  4. Create dashboard with predictions_total"
echo ""
