#!/bin/bash

echo "=========================================="
echo "RECOVERING FULL STACK"
echo "=========================================="
echo ""

# Stop everything
echo "🛑 Stopping all containers..."
docker-compose down

# Update prometheus.yml to use service name
echo "📝 Fixing monitoring/prometheus.yml..."
cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'heart-disease-api'
    static_configs:
      - targets: ['api:5000']
    metrics_path: '/metrics'
EOF

# Create complete docker-compose.yml
echo "📝 Restoring docker-compose.yml with API..."
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
      - ./data:/app/data
    environment:
      - FLASK_ENV=production
    networks:
      - monitoring
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

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
    depends_on:
      - api

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

echo "✓ Files updated"
echo ""

# Build and start everything
echo "🔨 Building Docker image..."
docker build -t heart-disease-api .

echo ""
echo "🚀 Starting full stack..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check status
echo ""
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "=========================================="
echo "✅ RECOVERY COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 Services:"
echo "   API:        http://localhost:5000"
echo "   Health:     http://localhost:5000/health"
echo "   Metrics:    http://localhost:5000/metrics"
echo "   Prometheus: http://localhost:9090"
echo "   Grafana:    http://localhost:3000 (admin/admin)"
echo ""

# Test API
echo "🧪 Testing API..."
curl -s http://localhost:5000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:5000/health

echo ""
echo ""
echo "📋 Useful Commands:"
echo "   docker-compose logs -f api          # View API logs"
echo "   docker-compose logs -f prometheus   # View Prometheus logs"
echo "   docker-compose restart api          # Restart API"
echo "   docker-compose down                 # Stop all"
echo ""
